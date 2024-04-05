require("hl")

local db = require("htl.db")
local urls = require("htl.db.urls")

local Config = require("htl.Config")
local metadata = require("htl.db.metadata")

require("htc.cli")("hnetxt", {
    new = require("htc.new"),
    project = require("htc.project"),
    clean = {
        description = "clean the db",
        action = db.clean,
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
        {"date", description = "date (YYYYMMDD); default today", default = os.date('%Y%m%d'), convert = tostring},
        action = function(args) print(require("htl.track")():touch(args)) end,
    },
    x_of_the_day = {
        description = "set the x-of-the-day files",
        {"+r", target = "rerun", description = "rerun", switch = "on"},
        {"date", description = "date (YYYYMMDD); default today", default = os.date('%Y%m%d')},
        action = require("htl.db.samples").run,
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
            convert = function(p) return urls:where({path = Path.from_commandline(p)}).id end,
        },
        {"-p --path", default = Path.cwd(), convert=Path.from_commandline},
        {"+f", target = "include_urls", description = "print file urls", switch = "on"},
        {"+l", target = "include_links", description = "print links", switch = "on"},
        {"+v", target = "include_values", description = "print values", switch = "off"},
        {"+t", target = "include_tags", description = "print tags", switch = "off"},
        {"+V", target = "exclude_unique_values", description = "exclude unique values", switch = "off"},
        {"+m", target = "record_missing", description = "record metadata for files without any", switch = "off"},
        {"+I", target = "is_a_only", description = "show non-'is a' keys", switch = "on"},
        action = function(args)
            if #args.conditions > 0 then
                args.include_urls = not args.include_urls
                args.include_values = not args.include_values
            end
            print(metadata.get_dict(args))
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

            local url_ids = urls:get(q):col('id')

            if args.rerecord then
                url_ids:foreach(function(u) metadata:remove({url = u}) end)
            end

            metadata.record_missing(url_ids)
        end,
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
    test = {
        description = "test",
        {"+r", target = "rerun", description = "rerun", switch = "on"},
        {"date", description = "date (YYYYMMDD); default today", default = os.date('%Y%m%d')},
        action = function(args)
        end,
    },
})
