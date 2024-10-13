require("htl")

require("htl.cli")({
    name = "hnetxt",
    alias = "ht",
    commands = {
        project = require("htc.project"),
        journal = {
            alias = true,
            edit = require("htl.journal"),
            call_with = [[-c "lua require('zen-mode').toggle()"]],
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
            {"source", args = "1", convert = Path.from_commandline},
            {"target", args = "1", convert = Path.from_commandline},
            action = require("htc.move").run,
        },
        remove = {
            alias = "rm",
            {"path", args = "1", convert = Path.from_commandline},
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
            {"-p --path", default = Path.cwd(), description = "dir", convert=Path.from_commandline},
            edit = function(args)
                local p = args.path:join("1.md")

                while p:exists() do
                    p = p:with_stem(tostring(tonumber(p:stem()) + 1))
                end

                local page = args.page and tostring(args.page) or ''
                
                return string.format([[%s +"lua require('htn.ui').quote(%s)"]], p, page)
            end,
        },
        ontology = {
            alias = "on",
            description = "print the ontology",
            {
                "conditions",
                args = "*",
                default = List(),
                action="concat",
                description = List({
                    "filter conditions:",
                    "    #taxon      →    taxon",
                    "    @tag        →    @tag*",
                    "    key         →    key (any val)",
                    "    +key        →    *key",
                    "    key+        →    key*",
                    "    key:val     →    key = val (val can be a file)",
                    "    key:val-    →    key ≠ val",
                    "    key:a,b     →    key = a or b",
                    "    :val        →    anykey = val",
                    "    ::val       →    apply recursively",
                }):join("\n"),
            },
            {"-p --path", default = Path.cwd(), convert = Path.from_commandline},
            {"+i", target = "include_instances", description = "include instances", switch = "on"},
            {"+I", target = "instances_only", description = "only print instances", switch = "on"},
            {"+a", target = "by_attribute", description = "by attribute", switch = "on"},
            {"+t", target = "by_tag", description = "by tag", switch = "on"},
            {"+V", target = "include_attribute_values", description = "exclude attribute values", switch = "off"},
            print = require("htc.Ontology"),
        },
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
                    local lines = List({string.format("is a: %s", args.part_of_speech)})

                    if args.word:match("/") then
                        lines:append(string.format("language: %s", path:parent():name()))
                    end

                    lines:extend({"", "", ""})
                    path:write(lines)
                end

                local id = DB.urls:insert({path = path})

                local Metadata = require("htl.Metadata")

                Metadata.record(DB.urls:where({id = id}))

                return path
            end,
        },
        clean = {
            description = "clean the db",
            action = require("htl.db").clean,
        },
        persist = {
            description = "save things used by services",
            {"+r", target = "reparse_taxonomy", description = "reparse taxonomy", switch = "on"},
            action = function(args)
                DB.Log:persist()
                DB.Paths:persist()
                require("htl.Taxonomy")()

                if args.reparse_taxonomy then
                    require("htl.Metadata").persist()
                end
            end
        },
        add = {
            alias = true,
            {"title_words", default = List(), action="concat", args = "*"},
            {"-D --directory", default = Path.cwd(), convert=Path.from_commandline},
            {"-d --date", default = os.date('%Y%m%d')},
            {"-i --instance_type"},
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
                    
                    local url = DB.urls:get_file(path)
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
            {"path", args = "1", convert = Path.from_commandline},
            {"+p", target = "private", description = "leave private headings in", switch = "on"},
            {
                "-d --directory",
                description = "output directory",
                default = Path.home / "Desktop",
                convert = Path.from_commandline,
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
                os.execute(string.format("pandoc --pdf-engine=lualatex -s -o %s %s", pdf, tmp))
                tmp:unlink()
            end
        },
        -- etyparse = require("htc.ety"),
    }
})
