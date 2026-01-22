#!/bin/bash
#
# Check if staging needs to sync with main (e.g., after PR merge)
# Used by Claude Code SessionStart hook
#

git fetch origin --quiet 2>/dev/null

# Check if main has commits that staging doesn't
BEHIND=$(git rev-list --count origin/staging..origin/main 2>/dev/null || echo "0")

if [ "$BEHIND" -gt 0 ]; then
    echo "⚠️  Staging is $BEHIND commit(s) behind main. Run /push-pr to sync."
else
    echo "✓ Staging is in sync with main"
fi
