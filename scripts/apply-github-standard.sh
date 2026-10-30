#!/usr/bin/env bash
# Apply the GitHub repository standard from GITHUB-SETTINGS.md to one repository.
#
#   scripts/apply-github-standard.sh OWNER/REPO [--dry-run] [--check "Job name"]...
#
# Without --check, the required checks are read from the repository's current branch
# protection or "main" ruleset. Every run first saves the current settings to
# backups/<repo>-<timestamp>/ so they can be restored by hand.
set -euo pipefail

REPO="${1:?usage: apply-github-standard.sh OWNER/REPO [--dry-run] [--check NAME]...}"
shift
DRY=0
CHECKS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --check) CHECKS+=("$2"); shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

KIT="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP="$KIT/backups/${REPO//\//-}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
BRANCH=$(gh api "repos/$REPO" --jq .default_branch)
ACTIONS_APP_ID=15368

run() { if [ "$DRY" = 1 ]; then echo "DRY: $*"; else "$@"; fi; }

echo "== $REPO (default branch: $BRANCH), backup in $BACKUP"
gh api "repos/$REPO" > "$BACKUP/repo.json"
gh api "repos/$REPO/branches/$BRANCH/protection" > "$BACKUP/protection.json" 2>/dev/null || echo '{}' > "$BACKUP/protection.json"
gh api "repos/$REPO/rulesets" > "$BACKUP/rulesets.json"
for id in $(gh api "repos/$REPO/rulesets" --jq '.[].id'); do
  gh api "repos/$REPO/rulesets/$id" > "$BACKUP/ruleset-$id.json"
done
gh api "repos/$REPO/labels" --paginate > "$BACKUP/labels.json"
gh api "repos/$REPO/actions/permissions/workflow" > "$BACKUP/actions.json"

# Required checks: given, or detected from the protection, or from the existing "main" ruleset.
if [ ${#CHECKS[@]} -eq 0 ]; then
  while IFS= read -r c; do [ -n "$c" ] && CHECKS+=("$c"); done < <(
    python3 -I - "$BACKUP" <<'EOF'
import glob, json, sys
d = sys.argv[1]
p = json.load(open(f"{d}/protection.json"))
found = (p.get("required_status_checks") or {}).get("contexts") or []
if not found:
    for f in glob.glob(f"{d}/ruleset-*.json"):
        r = json.load(open(f))
        for rule in r.get("rules", []):
            if rule["type"] == "required_status_checks":
                found += [c["context"] for c in rule["parameters"]["required_status_checks"]]
print("\n".join(dict.fromkeys(found)))
EOF
  )
fi
[ ${#CHECKS[@]} -gt 0 ] || { echo "no required checks found; pass --check" >&2; exit 1; }
printf 'required checks: %s\n' "${CHECKS[@]}"

# 1. Merge settings.
run gh api -X PATCH "repos/$REPO" --silent \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK \
  -F delete_branch_on_merge=true -F allow_auto_merge=false

# 2. One ruleset named "main" on the default branch, with no bypass.
python3 -I - "$BACKUP/ruleset-new.json" "$ACTIONS_APP_ID" "${CHECKS[@]}" <<'EOF'
import json, sys
out, app, checks = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
ruleset = {
    "name": "main",
    "target": "branch",
    "enforcement": "active",
    "bypass_actors": [],
    "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
    "rules": [
        {"type": "deletion"},
        {"type": "non_fast_forward"},
        {"type": "required_linear_history"},
        {"type": "required_signatures"},
        {"type": "pull_request", "parameters": {
            "allowed_merge_methods": ["squash"],
            "dismiss_stale_reviews_on_push": True,
            "require_code_owner_review": False,
            "require_last_push_approval": False,
            "required_approving_review_count": 0,
            "required_review_thread_resolution": True,
        }},
        {"type": "required_status_checks", "parameters": {
            "strict_required_status_checks_policy": True,
            "required_status_checks": [{"context": c, "integration_id": app} for c in checks],
        }},
    ],
}
json.dump(ruleset, open(out, "w"), indent=1)
EOF
MAIN_ID=$(gh api "repos/$REPO/rulesets" --jq '[.[] | select(.name == "main")][0].id // empty')
if [ -n "$MAIN_ID" ]; then
  run gh api -X PUT "repos/$REPO/rulesets/$MAIN_ID" --input "$BACKUP/ruleset-new.json" --silent
else
  run gh api -X POST "repos/$REPO/rulesets" --input "$BACKUP/ruleset-new.json" --silent
fi
# Any other ruleset on the repository is removed, so one place holds the rules.
for id in $(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name != "main") | .id'); do
  run gh api -X DELETE "repos/$REPO/rulesets/$id" --silent
done

# 3. Remove the classic protection only once the ruleset is active.
if [ "$DRY" = 0 ]; then
  state=$(gh api "repos/$REPO/rulesets" --jq '[.[] | select(.name == "main")][0].enforcement')
  [ "$state" = "active" ] || { echo "ruleset not active; classic protection kept" >&2; exit 1; }
fi
if [ "$(cat "$BACKUP/protection.json")" != "{}" ]; then
  run gh api -X DELETE "repos/$REPO/branches/$BRANCH/protection" --silent
fi

# 4. Actions: read-only token by default, and no PR approvals from workflows.
run gh api -X PUT "repos/$REPO/actions/permissions/workflow" --silent \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false

# 5. Labels: one per Conventional Commit type plus triage labels, in one palette.
#    Labels the project adds for itself are left as they are.
while IFS='|' read -r name color desc; do
  if gh api "repos/$REPO/labels/$(python3 -I -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$name")" --silent 2>/dev/null; then
    run gh label edit "$name" -R "$REPO" --color "$color" --description "$desc"
  else
    run gh label create "$name" -R "$REPO" --color "$color" --description "$desc"
  fi
done <<'EOF'
enhancement|a2eeef|New feature or request (feat)
bug|d73a4a|Something isn't working (fix)
documentation|0075ca|Improvements or additions to documentation (docs)
style|c5def5|Formatting and wording with no change in behavior
refactor|1d76db|Code change that neither fixes a bug nor adds a feature
perf|fbca04|Performance improvement
test|0e8a16|Adding or correcting tests
ci|5319e7|Changes to CI configuration and workflows
build|006b75|Changes to the build system or dependencies
chore|ededed|Maintenance with no change to the product
duplicate|cfd3d7|This issue or pull request already exists
invalid|e4e669|This doesn't seem right
wontfix|ffffff|This will not be worked on
question|d876e3|Further information is requested
help wanted|008672|Extra attention is needed
good first issue|7057ff|Good for newcomers
EOF

# 6. Secret scanning and push protection, where GitHub offers them for this repository.
run gh api -X PATCH "repos/$REPO" --silent --input - <<'EOF' || echo "secret scanning not available here; skipped"
{"security_and_analysis": {"secret_scanning": {"status": "enabled"}, "secret_scanning_push_protection": {"status": "enabled"}}}
EOF

echo "== done: $REPO"
