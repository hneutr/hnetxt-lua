require("htl")

require("htc.cli")("hnetxt", {
    project = require("htc.project"),
    clean = {description = "clean the db", action = require("htl.db").clean},
    journal = {description = "print the journal path", print = require("htl.journal")},
    aim = {description = "print the goals path", print = require("htl.goals")},
    language = {description = "print the language dir", print = function() return Conf.paths.language_dir end},
    persist = {
        description = "save things used by services",
        {"+r", target = "reparse_taxonomy", description = "reparse taxonomy", switch = "on"},
        action = function(args)
            DB.Log:persist()
            DB.Paths:persist()

            if args.reparse_taxonomy then
                require("htl.Taxonomy.Parser"):persist()
            end
        end
    },
    move = {
        description = "mv within a project",
        {"source", args = "1", convert = Path.from_commandline},
        {"target", args = "1", convert = Path.from_commandline},
        action = require("htc.move").run,
    },
    remove = {
        description = "rm within a project",
        {"path", args = "1", convert = Path.from_commandline},
        {"+r", target = "recursive", description = "delete recursively", switch = "on"},
        {"+d", target = "directories", description = "delete directories", switch = "on"},
        {"+f", target = "force", description = "force", switch = "on"},
        action = require("htc.remove").run,
    },
    track = {
        description = "print the tracking path",
        {"date", description = "date (YYYYMMDD); default today", default = os.date('%Y%m%d')},
        action = DB.Log.ui.cli,
    },
    x_of_the_day = {
        description = "set the x-of-the-day files",
        {"+r", target = "rerun", description = "rerun", switch = "on"},
        {"date", description = "date (YYYYMMDD); default today", default = os.date('%Y%m%d')},
        action = DB.samples.run,
    },
    quote = {
        description = "add a quote",
        {"-p --path", default = Path.cwd(), description = "media dir", convert=Path.from_commandline},
        print = function(args)
            local p = args.path:join("1.md")

            while p:exists() do
                p = p:with_stem(tostring(tonumber(p:stem()) + 1))
            end

            return p
        end,
    },
    on = {
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
        {"-p --path", default = Path.cwd(), convert=Path.from_commandline},
        {"+i", target = "include_instances", description = "include instances", switch = "on"},
        {"+I", target = "instances_only", description = "only print instances", switch = "on"},
        {"+a", target = "by_attribute", description = "by attribute", switch = "on"},
        print = require("htc.Ontology"),
    },
    test = {
        action = function() end,
    },
})
