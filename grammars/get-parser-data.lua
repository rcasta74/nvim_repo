#!/usr/bin/env lua

local function get_script_directory()
  local source = debug.getinfo(1, "S").source

  -- Lua prefixes script paths with "@"
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end

  return source:match("^(.*[/\\])") or "./"
end

local function last_path_component(url)
  -- Remove trailing slashes, then an optional .git suffix.
  return url
    :gsub("/+$", "")
    :match("([^/]+)%.git$") -- handles URLs ending in .git
    or url:gsub("/+$", ""):match("([^/]+)$")
end

local script_dir = get_script_directory()

local project_root = script_dir .. ".."

local treesitter_dir =
  project_root .. "/plugins/nvim-treesitter"

local parsers_file =
  treesitter_dir .. "/lua/nvim-treesitter/parsers.lua"

local parsers = assert(dofile(parsers_file))

local names = {}

for parser_name in pairs(parsers) do
    table.insert(names, parser_name)
end

table.sort(names)

for _, parser_name in ipairs(names) do
    local parser = parsers[parser_name]
    local install_info = parser.install_info or {}

    if install_info.url and install_info.revision then
        print(
            parser_name .. "\t" ..
            last_path_component(tostring(install_info.url)) .. "\t" ..
            tostring(install_info.url) .. "\t" ..
            tostring(install_info.revision)
        )
    end
end
