---
name: push-pr
description: Push to staging, auto-create PR, and sync after merge
version: 2.0.0
---

# Push with Auto-PR

Push local commits to staging, automatically create/update a PR to main, and sync after merge.

## Usage

```
/push-pr
```

## Instructions

When the user invokes `/push-pr`:

### 1. Check current state

First, check if we're on staging and if there's an existing PR:

```bash
CURRENT_BRANCH=$(git branch --show-current)
PR_STATE=$(gh pr view --json state --jq '.state' 2>/dev/null || echo "NONE")
```

### 2. Handle merged PR (sync staging with main)

If PR state is `MERGED`, sync staging with main to prevent the "compare" banner:

```bash
git fetch origin main
git merge origin/main --no-edit
git push origin staging
```

Then report: "Synced staging with main after merge. Ready for new changes!"

**Skip to end** - no need to create a new PR.

### 3. Push local changes

If there are commits to push:

```bash
git push origin staging
```

Report which commits were pushed.

### 4. Create or report PR

**Check for existing open PR**:
```bash
gh pr list --base main --head staging --state open --json number --jq 'length'
```

**If no open PR exists**, create one:
```bash
gh pr create --base main --head staging \
  --title "$(git log -1 --format='%s')" \
  --body "$(cat <<'BODY'
## Changes
$(git log origin/main..origin/staging --oneline)

## Test plan
- [ ] Verify staging site: https://automatable-website-testing-b2m3s.ondigitalocean.app

🤖 Generated with [Claude Code](https://claude.com/claude-code)
BODY
)"
```

**If PR already exists**, report its URL:
```bash
gh pr view --json url --jq '.url'
```

### 5. Remind about post-merge sync

After reporting the PR, remind the user:

> "After merging, run `/push-pr` again to sync staging with main."

## Safety

- Never use `--force` unless explicitly requested
- Only operates on the staging branch
- Sync operation uses `--no-edit` to avoid interactive prompts
