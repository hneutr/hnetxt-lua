local Util = require("htc.util")
local Path = require("hl.path")
local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")
local Colors = require("htc.colors")
local Journal = require("htl.journal")

local Config = require("htl.config")
local Project = require("htl.project")
local Link = require("htl.text.link")

local max_line_length = 80
local divider = tostring(require("htl.text.divider")("large"))

local date_parts = {
    year = os.date("%Y"),
    month = os.date("%m"),
    day = os.date("%d"),
}

function color_path(path)
    return Colors("%{magenta}" .. path .. "%{reset}")
end

function get_journal_dir(project_name)
    local project_dir
    if #project_name > 0 then
        local project = Project(project_name)
        if project then
            project_dir = project.root
        end
    end

    return Path.parent(Journal(project_dir))
end

function enforce_line_length(line)
    local lines = List()
    local current_line = ""
    for _, word in ipairs(line:split(" ")) do
        if #current_line + #word > max_line_length then
            lines:append(current_line)
            current_line = ""
        end

        current_line = current_line .. " " .. word
    end
    lines:append(current_line)

    return lines:transform(function(l) return "    " .. l end):join("\n")
end

function show(args)
    local stem_to_path_map = Dict()
    for _, path in ipairs(Path.iterdir(args.dir, {recursive = false, dirs = false})) do
        stem_to_path_map[Path.stem(path)] = path
    end

    local stems = stem_to_path_map:keys():sorted()

    stems = stems:filter(function(stem)
        local pass = true

        if args.year then
            local year = stem:sub(1, 4)
            pass = pass and year == args.year
        end

        if args.month then
            local month = stem:sub(5, 6)
            pass = pass and month == args.month
        end

        return pass
    end)

    if args.number > 0 then
        stems = stems:slice(#stems - args.number + 1)
    elseif args.number < 0 then
        stems = stems:slice(args.number - 1, args.number - 1)
    end

    local content_blocks = List()
    stems:foreach(function(stem)
        local path = stem_to_path_map[stem]
        local content = List()
        for _, line in ipairs(Path.readlines(path)) do
            content:append(enforce_line_length(line))
        end

        if Path.is_relative_to(path, Path.cwd()) then
            path = Path.relative_to(path, Path.cwd())
        end

        content_blocks:append(color_path(path) .. ":\n" .. content:join("\n"))
    end)

    print(content_blocks:join("\n\n"))
end

function convert(args)
    local paths_to_convert = List(Path.iterdir(args.dir, {recursive = false, dirs = false}))
    paths_to_convert = paths_to_convert:filter(function(p) return #Path.stem(p) == 6 end)

    local dateless_paths = Set()
    local path_to_content_map = Dict()
    paths_to_convert:foreach(function(p)
        local entries = List(Path.read(p):strip():removesuffix(divider):split(divider)):mapm("strip")
        
        entries:foreach(function(entry)
            local date_line, content = unpack(entry:split("\n\n", 1))
            local date = Link.from_str(date_line).label

            if #date == 0 then
                dateless_paths = dateless_paths + p
            end

            local entry_path = Path.with_stem(p, date)
            path_to_content_map[entry_path] = content
        end)
    end)

    if args.write then
        path_to_content_map:foreach(function(path, content) Path.write(path, content) end)
        paths_to_convert:foreach(Path.unlink)
    else
        Dict.keys(dateless_paths):foreach(print)
    end
end

return {
    description = "return the path to a journal",
    {"--dir", hidden = true, default = Util.default_project(), convert = get_journal_dir},
    {"project", description = "project name", args = "?", target = 'dir', convert = get_journal_dir},
    {"+w", target = "write", default = false, action='store_true'},
    {"-d", target = "date", default = os.date("%Y%m%d")},
    {"-y", target = "year"},
    {
        "-m",
        target = "month",
        convert = function(m)
            if #m == 1 then
                m = "0" .. m
            end
            return m
        end
    },
    {
        "-n",
        target = "number",
        default = 1,
        convert = function(n)
            if n:endswith("%-") then
                n = "-" .. n:removesuffix("%-")
            end
            
            return tonumber(n)
        end,
    },
    {
        "-a",
        target = "action",
        description = "what to do",
        default = "touch",
        choices = {"touch", "show", "convert"},
        convert = {
            show = show,
            convert = convert,
            touch = function(args) print(Path.joinpath(args.dir, args.date .. ".md")) end,
        },
    },
    action = function(args)
        args.dir = args.dir or Config.get("journal").global_dir
        args.action(args)
    end,
}
