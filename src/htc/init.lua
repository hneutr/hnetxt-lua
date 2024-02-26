require("approot")("/Users/hne/lib/hnetxt-lua/")

local List = require("hl.List")
local Dict = require("hl.Dict")
local Set = require("hl.Set")
local Path = require("hl.Path")

local db = require("htl.db")
local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

local Config = require("htl.Config")
local Metadata = require("htl.Metadata")
local Snippet = require("htl.snippet")

local Command = require("htc.command")

local parser = require("argparse")("hnetxt")

local commands = List()
Dict({
    new = require("htc.new"),
    tags = require("htc.tags"),
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
        {"+r", target = "recursive", description = "delte recursively", switch = "on"},
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
        action = function(args)
            local today = os.date("%Y%m%d")

            local sources = List()
            Dict(Config.get("x-of-the-day")):foreach(function(key, command)
                local path = Config.paths.x_of_the_day_dir:join(key, today)

                if not path:exists() or args.rerun then
                    local source = Metadata.Files(command):get_random_file()
                    path:write(tostring(Snippet(source)))
                    sources:append(string.format("%s: %s", key, source))
                end
            end)

            if #sources > 0 then
                Config.paths.x_of_the_day_dir:join(".sources", today):write(sources)
            end
        end,
    },
    test = {
        description = "blahh",
        action = function(args)
            local metadata = require("htl.db.metadata")

            metadata:remove()

            local u = List()
            urls:get({
                where = {project = "chasefeel"},
                contains = {path = "/Users/hne/Documents/text/written/fiction/chasefeel/glossary/*"}
            }):foreach(function(url)
                u:append(url.id)
                metadata:save_file_metadata(url.path)
            end)

            print(metadata.get_dict(u, false))
        end
    },
}):foreach(function(name, config)
    commands:append(Command:add(parser, config, name))
end)

parser:group("commands", unpack(commands)):parse()
