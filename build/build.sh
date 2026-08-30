#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd -P
)

cd -- "$script_dir/neovim"

# prepare deps
mkdir -p .deps/build
ln -nfs ../../../deps/src .deps/build

# build dpes
make deps DEPS_CMAKE_FLAGS=-DUSE_EXISTING_SRC_DIR=ON

# build neovim 
make CMAKE_BUILD_TYPE=Release


