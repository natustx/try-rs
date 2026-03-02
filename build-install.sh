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
rm -f try-rs ~/prj/util/bin/try ~/prj/util/bin/try-rs
cargo clean

# Build
cargo build --release

# Install binary as "try"
mkdir -p ~/prj/util/bin
cp target/release/try-rs ~/prj/util/bin/try
chmod +x ~/prj/util/bin/try

echo "Installed: $(~/prj/util/bin/try --version 2>/dev/null || echo 'try')"
