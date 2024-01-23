local Dict = require("hl.Dict")
local Path = require("hl.path")
local Colorize = require("htc.colorize")

local projects = require("htl.db").get().projects

local arg_definitions = {
    title = {"title", default = Path.name(Path.cwd()), args = "1"},
    path = {"-p --path", default = Path.cwd(), description = "dir", convert=Path.as_path},
}

return {
    require_command = false,
    action = function(args)
        if #Dict(args):keys() == 1 then
            projects:get():sorted(function(a, b)
                return a.created < b.created
            end):foreach(function(p)
                print(Colorize(p.created, 'yellow') .. ": " .. p.title)
            end)
        end
    end,
    commands = {
        add = {
            arg_definitions.title,
            arg_definitions.path,
            {"-d --date", default = os.date("%Y%m%d")},
            action = function(args)
                projects:insert({title = args.title, path = args.path, created = args.date})
            end,
        },
        remove = {
            arg_definitions.title,
            action = function(args)
                projects:remove({title = args.title})
            end,
        },
    }
}
