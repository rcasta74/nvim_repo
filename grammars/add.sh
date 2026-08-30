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

mkdir -p "$grammars_dir"

parser_data=$("$script_dir/get-parser-data.lua")

declare -A selected

dialog_items=()

while IFS=$'\t' read -r parser_name grammar_name url revision; do
    [[ -z "$parser_name" ]] && continue

    if [[ -e "$grammars_dir/$grammar_name/.git" ]]; then
        status="on"
    else
        status="off"
    fi

    dialog_items+=(
        "$parser_name"
        "$grammar_name"
        "$status"
    )
done <<< "$parser_data"


selected_parsers="$(
    dialog \
        --separate-output \
        --title "Select Tree-sitter Parsers" \
        --checklist \
        "Use SPACE to select parsers, then ENTER to continue:" \
        20 70 12 \
        "${dialog_items[@]}" \
        2>&1 >/dev/tty
)" || {
    echo "Selection cancelled."
    exit 0
}

while IFS= read -r parser_name; do
    [[ -z "$parser_name" ]] && continue
    selected["$parser_name"]=1
done <<< "$selected_parsers"

added=0
skipped=0

declare -A processed_urls

while IFS=$'\t' read -r parser_name grammar_name url revision; do
    [[ -z "$parser_name" ]] && continue

    if [[ -z "${selected[$parser_name]:-}" ]]; then
        continue
    fi

    # Do not process the same repository more than once.
    if [[ -n "${processed_urls[$url]:-}" ]]; then
        echo "Skipping $parser_name: repository already selected"
        continue
    fi

    processed_urls["$url"]=1

    submodule_path="$grammars_dir/$grammar_name"

    if git config --file .gitmodules \
        --get-regexp '^submodule\..*\.path$' 2>/dev/null |
        awk -v path="$submodule_path" '$2 == path { found = 1 } END { exit !found }'
    then
        echo "Skipping $parser_name: already a submodule"
        ((skipped += 1))
        continue
    fi

    if [[ -e "$submodule_path" ]]; then
        echo "Skipping $parser_name: path already exists"
        ((skipped += 1))
        continue
    fi

    echo "Adding $parser_name..."
    echo "  URL:      $url"
    echo "  Revision: $revision"
    echo "  Path:     $submodule_path"

    git submodule add --depth 1 "$url" "$submodule_path"
    git config -f $repo_root/.gitmodules submodule.$submodule_path.shallow true

    git -C "$submodule_path" fetch --depth 1 origin "$revision"
    git -C "$submodule_path" checkout --detach "$revision"


    ((added += 1))
done <<< "$parser_data"

echo
echo "Added: $added"
echo "Skipped: $skipped"

git status --short

