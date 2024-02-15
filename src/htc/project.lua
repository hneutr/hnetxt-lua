local Dict = require("hl.Dict")
local Path = require("hl.Path")
local Colorize = require("htc.colorize")

local projects = require("htl.db").get().projects

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
            {"title", default = Path.cwd():name(), args = "1"},
            {"-p --path", default = Path.cwd(), description = "dir", convert=Path.as_path},
            {"-d --date", default = os.date("%Y%m%d")},
            action = function(args)
                projects:insert({title = args.title, path = args.path, created = args.date})
            end,
        },
        remove = {
            {"title", default = Path.cwd():name(), args = "1"},
            action = function(args)
                projects:remove({title = args.title})
            end,
        },
    }
}
