require("htl")

require("htc.cli")("hnetxt", {
    new = require("htc.new"),
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
    persist = {
        description = "save things used by services",
        action = function()
            DB.Log:record_all()
            DB.Paths:ingest()
        end
    },
    remove = {
        description = "rm within a project",
        {"path", args = "1", convert = Path.from_commandline},
        {"+r", target = "recursive", description = "delete recursively", switch = "on"},
        {"+d", target = "directories", description = "delete directories", switch = "on"},
        {"+f", target = "force", description = "force", switch = "on"},
        action = require("htc.remove").run,
    },
    journal = {
        description = "print the journal path",
        action = function() print(require("htl.journal")()) end,
    },
    aim = {
        description = "print the goals path",
        action = function() print(require("htl.goals")()) end,
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
        action = function(args)
            local path = args.path:join("1.md")

            while path:exists() do
                path = path:with_stem(tostring(tonumber(path:stem()) + 1))
            end

            print(path)
        end,
    },
    language = {
        description = "print the language dir",
        action = function(args) print(Conf.paths.language_dir) end,
    },
    tags = {
        description = "list tags",
        {
            "conditions",
            args = "*",
            default = List(),
            description = "the conditions to meet (fields:value?/@tag.subtag/exclusion-)", 
            action="concat",
        },
        {
            "--reference",
            description = "print references to this file",
            convert = function(p) return DB.urls:where({path = Path.from_commandline(p)}).id end,
        },
        {"-p --path", default = Path.cwd(), convert=Path.from_commandline},
        {"+f", target = "include_urls", description = "print file urls", switch = "on"},
        {"+l", target = "include_links", description = "print links", switch = "on"},
        {"+v", target = "include_values", description = "print values", switch = "off"},
        {"+t", target = "include_tags", description = "print tags", switch = "off"},
        {"+V", target = "exclude_unique_values", description = "exclude unique values", switch = "off"},
        {"+m", target = "record_missing", description = "record metadata for files without any", switch = "off"},
        {"+I", target = "is_a_only", description = "show non-'is a' keys", switch = "on"},
        {"+T", target = "apply_taxonomy", description = "don't apply the taxonomy", switch = "off"},
        action = function(args)
            if #args.conditions > 0 then
                args.include_urls = not args.include_urls
                args.include_values = not args.include_values
            end

            print(DB.metadata.get_dict(args))
        end
    },
    record_metadata = {
        description = "record metadata",
        {"-p --path", default = Path.cwd(), description = "restrict to this path", convert=Path.as_path},
        {"+a", target = "all", description = "don't restrict by path", switch = "on"},
        {
            "+r",
            target = "rerecord",
            description = "rerecord metadata for all files; if off, only operates on files missing metadata",
            switch = "on",
        },
        action = function(args)
            local q = {where = {resource_type = "file"}}

            if not args.all then
                q.contains = {path = string.format("%s*", args.path)}
            end

            local url_ids = DB.urls:get(q):col('id')

            if args.rerecord then
                url_ids:foreach(function(u) DB.metadata:remove({url = u}) end)
            end

            DB.metadata.record_missing(url_ids)
        end,
    },
    tax = {
        description = "print taxonomy",
        {"-p --path", default = Path.cwd(), convert=Path.from_commandline},
        {"+I", target = "include_instances", description = "exclude instances", switch = "off"},
        -- {"+a", target = "include_attributes", description = "include attributes", switch = "on"},
        {"+f", target = "instances_only", description = "only print instances", switch = "on"},
        -- {"+a", target = "attributes_only", description = "only attributes instances", switch = "on"},
        {
            "-s --subsets",
            target = "subsets",
            args = "*",
            default = List(),
            description = "subsets to include", 
            action = "concat",
        },
        action = function(args)
            -- args.path = Path("/Users/hne/Documents/text/written/fiction/chasefeel")

            -- utils.time_it("start")
            -- local printer = require("htl.Taxonomy.Printer")(args)
            -- utils.time_it("printer")
            -- local str = tostring(printer)
            -- utils.time_it("stringifying")
            -- print(str)
            
            local project = "chasefeel"
            -- project = "eidola"
            local path = DB.projects:where({title = project}).path
            -- path = path / "glossary"

            local ptaxonomy = require("htl.Taxonomy.Persistent")(path)
            print(ptaxonomy.taxon_instances)
        end,
    },
    reparse_relations = {
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
        {"+r", target = "rerun", description = "rerun", switch = "on"},
        {"date", description = "date (YYYYMMDD); default today", default = os.date('%Y%m%d')},
        action = function(args)
            print(os.date("%H:%M"))
            -- local Date = require("")
        end,
    },
})
