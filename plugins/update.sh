#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd -P
)

repo_root=$(
    cd -- "$script_dir" &&
    git rev-parse --show-toplevel
)

cd -- "$repo_root"

echo "Repository: $repo_root"

git submodule sync

git submodule update --init --remote -- plugins/

echo
echo "Submodule status:"
git submodule status -- plugins/

echo
echo "Changed files:"
git status --short

