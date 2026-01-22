#!/bin/bash
#
# Install git hooks for the automatable-website repository
#
# These hooks help prevent accidental commits/pushes to protected branches.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/hooks"
GIT_HOOKS_DIR="$(git rev-parse --git-dir 2>/dev/null)/hooks"

# Check if we're in a git repo
if [ ! -d "$GIT_HOOKS_DIR" ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Track if any hooks were installed/updated
installed=0
up_to_date=0

for hook in "$HOOKS_DIR"/*; do
    hook_name=$(basename "$hook")
    target="$GIT_HOOKS_DIR/$hook_name"

    # Check if hook already exists and is identical
    if [ -f "$target" ] && cmp -s "$hook" "$target"; then
        ((up_to_date++))
        continue
    fi

    # Backup existing hook if it's different
    if [ -f "$target" ] && [ ! -L "$target" ]; then
        echo "  ⚠️  $hook_name differs (backing up to $hook_name.backup)"
        mv "$target" "$target.backup"
    fi

    cp "$hook" "$target"
    chmod +x "$target"
    echo "  ✓ Installed $hook_name"
    ((installed++))
done

# Only show verbose output if something changed
if [ $installed -gt 0 ]; then
    echo ""
    echo "Git hooks installed:"
    echo "  - pre-commit: Prompts before committing on main"
    echo "  - pre-push: Prompts before pushing to main"
    echo ""
    echo "To bypass in emergencies: git commit --no-verify"
elif [ $up_to_date -gt 0 ]; then
    echo "✓ Git hooks already installed"
fi
