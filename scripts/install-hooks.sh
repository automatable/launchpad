#!/bin/bash
#
# Install git hooks for the launchpad repository
#
# These hooks help prevent accidental commits/pushes to protected branches.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/hooks"
GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"

echo "Installing git hooks..."

for hook in "$HOOKS_DIR"/*; do
    hook_name=$(basename "$hook")
    target="$GIT_HOOKS_DIR/$hook_name"

    if [ -f "$target" ] && [ ! -L "$target" ]; then
        echo "  ⚠️  $hook_name already exists (backing up to $hook_name.backup)"
        mv "$target" "$target.backup"
    fi

    cp "$hook" "$target"
    chmod +x "$target"
    echo "  ✓ Installed $hook_name"
done

echo ""
echo "Done! Hooks installed:"
echo "  - pre-commit: Prompts before committing on main"
echo "  - pre-push: Prompts before pushing to main"
echo ""
echo "To bypass a hook in an emergency, use --no-verify:"
echo "  git commit --no-verify"
echo "  git push --no-verify"
