require("htl")

require("htl.cli")({
    name = "hnetxt",
    alias = "ht",
    commands = {
        project = require("htc.project"),
        journal = {
            alias = true,
            edit = require("htl.journal"),
            call_with = [[-c Spruce]],
        },
        aim = {
            alias = true,
            edit = require("htl.goals"),
        },
        track = {
            alias = true,
            {"date", description = "date", default = os.date('%Y%m%d')},
            edit = DB.Log.ui.cli,
        },
        move = {
            alias = "mv",
            {"source", args = "1", convert = Path.from_cli},
            {"target", args = "1", convert = Path.from_cli},
            action = require("htc.move").run,
        },
        remove = {
            alias = "rm",
            {"path", args = "1", convert = Path.from_cli},
            {"+r", target = "recursive", description = "delete recursively", switch = "on"},
            {"+d", target = "directories", description = "delete directories", switch = "on"},
            {"+f", target = "force", description = "force", switch = "on"},
            action = require("htc.remove").run,
        },
        x_of_the_day = {
            description = "set the x-of-the-day files",
            {"+r", target = "rerun", description = "rerun", switch = "on"},
            {"date", description = "date", default = os.date('%Y%m%d')},
            action = DB.samples.run,
        },
        quote = {
            alias = true,
            description = "add a quote",
            {"page", description = "page number", args = "?"},
            {"-p --path", default = Path.cwd(), description = "dir", convert=Path.from_cli},
            edit = function(args)
                local p = args.path:join("1.md")

                while p:exists() do
                    p = p:with_stem(tostring(tonumber(p:stem()) + 1))
                end

                local page = args.page and tostring(args.page) or ''

                return string.format([[%s +"lua require('htn.ui').quote(%s)"]], p, page)
            end,
        },
        metadata = require('htc.Metadata'),
        ety = {
            alias = true,
            description = "open etymonline to the word",
            {"word", args = "1"},
            action = require("htl.ety").open,
        },
        define = {
            alias = true,
            description = "add a word to the dictionary",
            {"word", description = "word to add", args = 1},
            {"-p --part-of-speech", description = "part of speech", default = "word"},
            edit = function(args)
                local entry = Path.string_to_path(args.word .. ".md")
                local path = DB.projects:where({title = "dictionary"}).path / entry

                if not path:exists() then
                    local lines = List({
                        ("is a: %s"):format(args.part_of_speech),
                        "sense: ",
                        "components: ",
                    })

                    if args.word:match("/") then
                        lines:append(string.format("language: %s", path:parent():name()))
                    end

                    lines:extend({"", "", ""})
                    path:write(lines)
                end

                DB.Metadata.record(DB.urls:where({id = DB.urls:insert({path = path})}))

                return path
            end,
        },
        persist = {
            description = "save things used by services",
            {"+r", target = "reparse_metadata", description = "reparse metadata", switch = "on"},
            action = function(args)
                DB.Log:persist()
                DB.Paths:persist()
                DB.Taxonomy.refresh()

                if args.reparse_metadata then
                    DB.Metadata.reparse()
                end
            end
        },
        add = {
            alias = true,
            {"title_words", default = List(), action="concat", args = "*"},
            {"-D --directory", default = Path.cwd(), convert=Path.from_cli},
            {"-d --date", default = os.date('%Y%m%d')},
            {"-i --instance_type", description = "is a"},
            edit = function(args)
                local name = args.title_words:join(' ')
                local lines = List({
                    string.format("is a: %s", args.instance_type or ""),
                    "",
                    name,
                })

                List({
                    {", ", " "},
                    {"%s%s", "%s"},
                    {"-", "_"},
                    {"'"},
                    {'"'},
                    {"%."},
                    {"%s", "-"},
                    {[[ — ]], "---"},
                }):foreach(function(change)
                    local match, replacement = unpack(change)
                    name = name:gsub(match, replacement or "")
                end)

                local path = args.directory / string.format("%s.md", name)
                path:write(lines)

                if args.date then
                    DB.urls:insert({path = path})

                    local url = DB.urls.get_file(path)
                    if url then
                        DB.urls:update({
                            where = {id = url.id},
                            set = {created = args.date},
                        })
                    end
                end

                return string.format(
                    [[%s %s]],
                    path,
                    args.instance_type and "+" or [[+"lua vim.api.nvim_input('ggA')"]]
                )
            end,
        },
        setmd = {
            alias = true,
            description = "make a pdf of a markdown file",
            {"path", args = "1", convert = Path.from_cli},
            {"+p", target = "private", description = "leave private headings in", switch = "on"},
            {
                "-d --directory",
                description = "output directory",
                default = Path.home / "Desktop",
                convert = Path.from_cli,
            },
            action = function(args)
                local pdf = args.directory / string.format("%s.pdf", args.path:stem())
                local tmp = Path.tempdir / args.path:name()

                local Document = require("htl.text.Document")
                local doc = Document({
                    path = args.path,
                    private = args.private,
                })

                tmp:write(doc.lines)
                -- os.execute(string.format("pandoc --pdf-engine=lualatex -s -o %s %s", pdf, tmp))
                os.execute(string.format("pandoc -s -o %s %s", pdf, tmp))
                tmp:unlink()
            end
        },
        -- etyparse = require("htc.ety"),
    }
})
