require("htl.cli")({
    name = "project",
    require_command = false,
    action = function(args)
        if #Dict(args):keys() == 0 then
            local Color = require("htl.Color")

            DB.projects:get():sorted(function(a, b)
                return a.created < b.created
            end):foreach(function(p)
                local colors = {
                    bracket = "black",
                    date = "black",
                }

                local s = List({
                    Color("[", colors.bracket),
                    Color(p.created, colors.date),
                    Color("]", colors.bracket),
                    " ",
                    p.title,
                }):join("")
                print(s)
            end)
        end
    end,
    commands = {
        add = {
            {"title", default = Path.cwd():name(), description = "title", args = "1"},
            {"-p --path", default = Path.cwd(), description = "directory (default=cwd)", convert=Path.as_path},
            {"-c --created", default = os.date("%Y%m%d"), description = "start date"},
            action = function(args)
                args.path:mkdir()
                local TaxonomyParser = require("htl.Taxonomy.Parser")

                DB.projects:insert(args)
                args.path:glob("%.md$"):foreach(function(path)
                    DB.urls:insert({path = path})
                    TaxonomyParser:record(DB.urls:get_file(path))
                end)
            end,
        },
        remove = {
            {"title", default = Path.cwd():name(), description = "title (default=cwd.name)", args = "1"},
            action = function(args)
                DB.projects:remove({title = args.title})
            end,
        },
    }
})
