#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd -P
)

cd -- "$script_dir"

git -C deps clean -fdx
git -C neovim clean -fdx

