---
name: push-pr
description: Push branch and create PR to main with automatic preview deployment
version: 3.0.0
---

# Push with Auto-PR

Push local commits and create/update a PR to main. A preview app will be automatically deployed when the PR is created.

## Usage

```
/push-pr
```

## Instructions

When the user invokes `/push-pr`:

### 1. Check current state

First, verify we're not on main and check for existing PR:

```bash
CURRENT_BRANCH=$(git branch --show-current)

# Abort if on main
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "ERROR: Cannot push-pr from main branch"
    exit 1
fi

# Check for existing PR
PR_URL=$(gh pr view --json url --jq '.url' 2>/dev/null || echo "")
```

### 2. Push local changes

If there are commits to push:

```bash
git push -u origin "$CURRENT_BRANCH"
```

Report which commits were pushed.

### 3. Create or report PR

**If no PR exists**, create one:

```bash
gh pr create --base main \
  --title "$(git log -1 --format='%s')" \
  --body "$(cat <<'BODY'
## Changes
$(git log origin/main..HEAD --oneline)

## Test plan
- [ ] Verify preview app (URL will be posted in comments after deploy)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
BODY
)"
```

**If PR already exists**, report its URL and mention the preview will update:

```bash
gh pr view --json url --jq '.url'
```

### 4. Remind about preview

After reporting the PR, remind the user:

> "A preview app will be deployed automatically. Watch the PR comments for the preview URL (usually takes 2-3 minutes)."

## Safety

- Never use `--force` unless explicitly requested
- Refuses to run from main branch
- Always sets upstream tracking with `-u`
