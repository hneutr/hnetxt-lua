return {
    name = "project",
    alias = true,
    require_command = false,
    print = function(args)
        if #Dict(args):keys() == 1 then
            local Color = require("htl.Color")

            return DB.projects:get():sorted(function(a, b)
                return a.created < b.created
            end):transform(function(p)
                local colors = {
                    bracket = "black",
                    date = "black",
                }

                return Color({
                    {"[", colors.bracket},
                    {p.created, colors.date},
                    {"]", colors.bracket},
                    {p.title},
                })
            end):join("\n")
        end
    end,
    commands = {
        add = {
            {"title", default = Path.cwd():name(), description = "title", args = "1"},
            {"-p --path", default = Path.cwd(), description = "directory (default=cwd)", convert=Path.as_path},
            {"-c --created", default = os.date("%Y%m%d"), description = "start date"},
            action = function(args)
                args.path:mkdir()
                local Metadata = require("htl.Metadata")

                DB.projects:insert(args)
                args.path:glob("%.md$"):foreach(function(path)
                    DB.urls:insert({path = path})
                    Metadata.record(DB.urls:get_file(path))
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
}
