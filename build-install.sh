#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

# Pull latest if this is an update
if [ -d .git ]; then
    _CURRENT=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if git remote get-url upstream &>/dev/null; then
        git fetch origin
        if git show-ref --verify --quiet "refs/remotes/origin/$_CURRENT"; then
            git reset --hard "origin/$_CURRENT"
        fi
    else
        git pull --ff-only 2>/dev/null || true
    fi
fi

# Clean stale build artifacts
rm -f try-rs ~/prj/util/bin/try-rs
cargo clean

# Build
cargo build --release

# Install binary
mkdir -p ~/prj/util/bin
cp target/release/try-rs ~/prj/util/bin/try-rs
chmod +x ~/prj/util/bin/try-rs

echo "Installed: $(~/prj/util/bin/try-rs --version 2>/dev/null || echo 'try-rs')"

# Shell integration (idempotent, marker-based)
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
MARKER_BEGIN="# >>> try-rs >>>"
MARKER_END="# <<< try-rs <<<"
BLOCK=$(cat <<'SHELL'
# >>> try-rs >>>
export TRY_PATH="$HOME/prj/active/experiments"
eval "$(try-rs --setup-stdout zsh)"
# <<< try-rs <<<
SHELL
)

if [ -f "$ZSHRC" ]; then
    if grep -q "$MARKER_BEGIN" "$ZSHRC"; then
        # Remove existing block between markers
        sed -i'' "/$MARKER_BEGIN/,/$MARKER_END/d" "$ZSHRC"
    fi
    # Append block
    printf '\n%s\n' "$BLOCK" >> "$ZSHRC"
fi
