require("htl")

require("htc.cli")("hnetxt", {
    project = require("htc.project"),
    clean = {
        description = "clean the db",
        action = require("htl.db").clean,
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
    persist = {
        description = "save things used by services",
        action = function()
            DB.Log:record_all()
            DB.Paths:ingest()
        end
    },
    journal = {
        description = "print the journal path",
        print = require("htl.journal"),
    },
    aim = {
        description = "print the goals path",
        print = require("htl.goals"),
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
        {"-p --path", default = Path.cwd(), description = "media dir", convert=Path.as_path},
        print = function(args)
            local p = args.path:join("1.md")

            while p:exists() do
                p = p:with_stem(tostring(tonumber(p:stem()) + 1))
            end

            return p
        end,
    },
    language = {
        description = "print the language dir",
        print = function() return Conf.paths.language_dir end,
    },
    tax = {
        -- {
        --     "--reference",
        --     description = "print references to this file",
        --     convert = function(p) return DB.urls:where({path = Path.from_commandline(p)}).id end,
        -- },
        -- {"+v", target = "include_values", description = "print values", switch = "off"},
        -- {"+V", target = "exclude_unique_values", description = "exclude unique values", switch = "off"},
        description = "print the taxonomy",
        {
            "conditions",
            args = "*",
            default = List(),
            description = "the conditions to meet (fields:value?/@tag.subtag/exclusion-)", 
            action="concat",
        },
        {
            "-t --taxa",
            target = "taxa",
            args = "*",
            default = List(),
            description = "taxa to include", 
            action = "concat",
        },
        {"-p --path", default = Path.cwd(), convert=Path.from_commandline},
        {"+I", target = "include_instances", description = "exclude instances", switch = "off"},
        {"+f", target = "instances_only", description = "only print instances", switch = "on"},
        print = require("htl.Taxonomy.Printer"),
        --[[
            conditions grammar:

            1. "x"
                Relations.relation = "connection"
                Relations.type = startswith(x)
            2. "x: y"
                Relations.relation = "connection"
                Relations.type = x
                Relations.object = y

            3. "x: file.md"
                Relations.relation = "connection"
                Relations.type = "x"
                Relations.object = Elements.id for file.md
            4. ": file.md"
                Relations.relation = "connection"
                Relations.object = Elements.id for file.md

            5. "@x"
                Relations.relation = "tag"
                Relations.type = startswith(X)
            ]]
    },
    reparse = {
        description = "reparse relations",
        {"+C", target = "clean", description = "clean bad urls", switch = "off"},
        action = function(args)
            DB.Relations:drop()
            DB.Elements:drop()
            local urls = DB.urls:get({where = {resource_type = "file"}}):sorted(function(a, b)
                return tostring(a.path) < tostring(b.path)
            end)
            
            if args.clean then
                urls = urls:filter(function(u)
                    local keep = true

                    if not DB.projects.get_by_path(u.path) then
                        keep = false
                    end

                    if not u.path:exists() then
                        keep = false
                    end

                    if not keep then
                        DB.urls:remove({id = u.id})
                    end

                    return keep
                end)
            end

            local TParser = require("htl.Taxonomy.Parser")

            urls:foreach(function(u)
                print(u.path)
                TParser:record(u)
            end)
        end,
    },
    -- refs = {
    --     description = "print references to a file",
    --     {"-p --path", default = Path.cwd(), convert=Path.from_commandline},
    --     {"+T", target = "by taxonomy", description = "don't print within the taxonomy", switch = "off"},
    --     action = function(args)
    --     end,
    -- },
    test = {
        description = "test",
        action = function(args)
        end,
    },
})
