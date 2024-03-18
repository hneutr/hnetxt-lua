require("approot")("/Users/hne/lib/hnetxt-lua/")
require("hl")

local db = require("htl.db")
local urls = require("htl.db.urls")

local Config = require("htl.Config")
local metadata = require("htl.db.metadata")
local Snippet = require("htl.snippet")

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
        {"date", description = "date (YYYYMMDD); default today", default = os.date('%Y%m%d')},
        action = function(args)
            local date = args.date
            if type(date) == "string" then
                if date:startswith('m') then
                    date = tonumber(os.date('%Y%m%d')) - tonumber(date:removeprefix('m'))
                end
            end

            print(require("htl.track")():touch(date))
        end,
    },
    x_of_the_day = {
        description = "set the x-of-the-day files",
        {"+r", target = "rerun", description = "rerun", switch = "on"},
        {"date", description = "date (YYYYMMDD); default today", default = os.date('%Y%m%d')},
        action = function(args)
            local sources = List()
            Dict(Config.get("x-of-the-day")):foreach(function(key, cmd)
                local path = Config.paths.x_of_the_day_dir:join(key, args.date)

                if not path:exists() or args.rerun then
                    cmd.dir = Path(cmd.dir)
                    local ids = Set(metadata:get_urls(cmd):col('url')):vals()
                    math.randomseed(os.time())
                    local v = math.random()
                    local index = math.random(1, #ids)
                    local source = urls:where({id = ids[index]}).path
                    path:write(tostring(Snippet(source)))
                    sources:append(string.format("%s: %s", key, source))
                end
            end)

            if #sources > 0 then
                Config.paths.x_of_the_day_dir:join(".sources", args.date):write(sources)
            end
        end,
    },
    tags = {
        description = "list tags",
        {
            "conditions",
            args = "*",
            default = {},
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
        {"+a", target = "add_missing", description = "add metadata for files without any", switch = "off"},
        {"+I", target = "is_a_only", description = "show non-'is a' keys", switch = "off"},
        action = function(args)
            if #args.conditions > 0 then
                args.include_urls = not args.include_urls
                args.include_values = not args.include_values
            end
            print(metadata.get_dict(args))
        end
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
        {"-p --path", default = Path.cwd(), description = "project directory", convert=Path.as_path},
        action = function(args)
            local p = Path("/Users/hne/Documents/text/written/fiction/chasefeel/testing.md")
            local u = urls:where({path = p})
            print(require("inspect")(u))
            -- urls:add_if_missing(p)
            os.exit()
            
            print(require("inspect")(metadata:where({url = u.id})))
        end,
    },
})
