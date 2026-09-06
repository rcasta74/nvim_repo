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

git submodule sync
git submodule update --force --checkout --depth 1
git submodule foreach 'git branch -l | grep -q local && git branch -fD local; git checkout -b local'

