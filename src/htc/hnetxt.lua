require("htl")

require("htl.cli")({
    name = "hnetxt",
    alias = "ht",
    commands = {
        project = require("htc.project"),
        journal = {
            alias = true,
            description = "open the journal",
            edit = require("htl.journal"),
            call_with = [[-c "lua require('zen-mode').toggle()"]],
        },
        aim = {
            alias = true,
            description = "open daily aims",
            edit = require("htl.goals"),
        },
        track = {
            alias = true,
            description = "open the tracking file",
            {"date", description = "date", default = os.date('%Y%m%d')},
            edit = DB.Log.ui.cli,
        },
        move = {
            alias = "mv",
            description = "move tracked files",
            {"source", args = "1", convert = Path.from_commandline},
            {"target", args = "1", convert = Path.from_commandline},
            action = require("htc.move").run,
        },
        remove = {
            alias = "rm",
            description = "remove tracked files",
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
        -- etyparse = require("htc.ety"),
        define = {
            alias = true,
            description = "add a word to the dictionary",
            {"word", description = "word to add", args = "+"},
            {"-p --part-of-speech", description = "part of speech", default = "word"},
            edit = function(args)
                local entry = Path.string_to_path(List(args.word):join(" ") .. ".md")
                local path = DB.projects:where({title = "dictionary"}).path / entry

                if not path:exists() then
                    path:write(List({
                        string.format("is a: %s", args.part_of_speech),
                        "",
                        "",
                        "",
                    }))
                end

                local id = DB.urls:insert({path = path})

                local Parser = require("htl.Taxonomy.Parser")

                Parser:record(DB.urls:where({id = id}))

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
                    require("htl.Taxonomy.Parser"):persist()
                end
            end
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
    }
})
