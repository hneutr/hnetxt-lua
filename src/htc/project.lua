local Colorize = require("htc.Colorize")
local TaxonomyParser = require("htl.Taxonomy.Parser")

return {
    require_command = false,
    action = function(args)
        if #Dict(args):keys() == 1 then
            DB.projects:get():sorted(function(a, b)
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
            action = function(args)
                args.path:mkdir()
            
                DB.projects:insert(args)
                args.path:glob("%.md$"):foreach(function(path)
                    DB.urls:insert({path = path})
                    TaxonomyParser:record(DB.urls:get_file(path))
                end)
            end,
        },
        remove = {
            {"title", default = Path.cwd():name(), description = "project title", args = "1"},
            action = function(args)
                DB.projects:remove({where = {title = args.title}})
            end,
        },
    }
}
