require("approot")("/Users/hne/lib/hnetxt-lua/")

local argparse = require("argparse")

local Command = require("htc.command")
local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.path")
local db = require("htl.db")

local parser = argparse("hnetxt")

local Operator = require("htl.operator")
-- local Move = require("htl.move")

local commands = List()
Dict({
    new = require("htc.new"),
    tags = require("htc.tags"),
    project = require("htc.project"),
    clean = {
        description = "clean the db",
        action = function()
            db.clean()
        end
    },
    move = {
        description = "mv within a project",
        {"source", description = "what to move", args = "1", convert = Path.resolve},
        {"target", description = "where to move it", args = "1", convert = Path.resolve},
        -- Move(args.source, args.target)
        action = Operator.move,
    },
    remove = {
        description = "rm within a project",
        {"source", description = "what to remove", args = "1", convert = Path.resolve},
        action = function(args)
            local source = Path(args.source)

            local url = db.get()['urls']:where({path = source})

            if url then
                db.get()['mirrors']:remove({url = url.id})
                db.get()['urls']:remove({id = url.id})
            end

            local mirror = db.get()['mirrors']:where({path = source})

            if mirror then
                db.get()['mirrors']:remove({id = mirror.id})
            end

            source:unlink()
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
}):foreach(function(name, config)
    commands:append(Command:add(parser, config, name))
end)

parser:group("commands", unpack(commands)):parse()
