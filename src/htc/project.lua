local Colorize = require("htc.colorize")

local projects = require("htl.db").get().projects

return {
    require_command = false,
    action = function(args)
        if #Dict(args):keys() == 1 then
            projects:get():sorted(function(a, b)
                return a.created < b.created
            end):foreach(function(p)
                local colors = {
                    bracket = "black",
                    date = "black",
                }
                local s = List({
                    Colorize("[", colors.bracket),
                    Colorize(p.created, colors.date),
                    Colorize("]", colors.bracket),
                    " ",
                    p.title,
                }):join("")
                print(s)
            end)
        end
    end,
    commands = {
        add = {
            {"title", default = Path.cwd():name(), description = "project title", args = "1"},
            {"-p --path", default = Path.cwd(), description = "project directory", convert=Path.as_path},
            {"-c --created", default = os.date("%Y%m%d"), description = "project start date"},
            action = function(args) projects:insert(args) end,
        },
        remove = {
            {"title", default = Path.cwd():name(), description = "project title", args = "1"},
            action = function(args) projects:remove(args) end,
        },
    }
}
