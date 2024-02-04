require("approot")("/Users/hne/lib/hnetxt-lua/")

local argparse = require("argparse")

local Command = require("htc.command")
local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.path")
local db = require("htl.db")
local urls = require("htl.db.urls")
local mirrors = require("htl.db.mirrors")
local Move = require("htl.move")

local parser = argparse("hnetxt")

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
        action = function(args) Move(args.source, args.target) end,
    },
    remove = {
        description = "rm within a project",
        {"path", args = "1", convert = Path.from_commandline},
        action = function(args)
            local url = urls:where({path = args.path, resource_type = "file"})
            if url then
                mirrors:remove({url = url.id})
            end

            urls:remove({path = args.path})

            local mirror = mirrors:where({path = args.path})

            if mirror then
                mirrors:remove({id = mirror.id})
            end

            args.path:unlink()
        end,
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
        {"date", description = "date (YYYYMMDD); default=today", default = os.date('%Y%m%d')},
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
}):foreach(function(name, config)
    commands:append(Command:add(parser, config, name))
end)

parser:group("commands", unpack(commands)):parse()
