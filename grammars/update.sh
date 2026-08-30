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

treesitter_dir="$repo_root/plugins/nvim-treesitter"
parsers_file="$treesitter_dir/lua/nvim-treesitter/parsers.lua"
grammars_dir="grammars"

if [[ ! -f "$parsers_file" ]]; then
    echo "Parser file not found:" >&2
    echo "  $parsers_file" >&2
    exit 1
fi

if [[ ! -d "$grammars_dir" ]]; then
    echo "Grammar directory not found:" >&2
    echo "  $grammars_dir" >&2
    exit 1
fi

parser_data=$("$script_dir/get-parser-data.lua")

updated=0
skipped=0

declare -A processed_submodule

while IFS=$'\t' read -r parser_name grammar_name url revision; do
    [[ -z "$parser_name" ]] && continue

    submodule_path="$grammars_dir/$grammar_name"

    if [[ ! -e "$submodule_path/.git" ]]; then
        # echo "Skipping $parser_name: submodule is missing or not initialized"
        ((skipped += 1))
        continue
    fi

    # Do not process the same submodule more than once.
    if [[ -n "${processed_submodule[$submodule_path]:-}" ]]; then
        echo "Skipping $parser_name: submodule already selected"
        continue
    fi

    processed_submodule["$submodule_path"]=1

    echo "Updating $parser_name"
    echo "  Path: $submodule_path"
    echo "  Revision: $revision"

    git -C "$submodule_path" fetch --depth 1 origin "$revision"
    git -C "$submodule_path" checkout --detach "$revision"

    ((updated += 1))
done <<< "$parser_data"

echo
echo "Finished:"
echo "  Updated: $updated"
echo "  Skipped: $skipped"
echo
echo "Parent repository status:"
git status --short

