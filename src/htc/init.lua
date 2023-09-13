require("approot")("/Users/hne/lib/hnetxt-cli/")

local argparse = require("argparse")
local Command = require("htc.command")
local List = require("hl.List")

local groups = {
    {name = "Commands", commands = {"move", "remove", "journal", "aim", "new"}},
    {name = "Command groups", commands = {"project", "notes", "goals"}},
}

local parser = argparse("hnetxt")

function add_command(name)
    local config = require(string.format("htc.%s", name))
    return Command():add(parser, config, name)
end

for _, group in ipairs(groups) do
    parser:group(group.name, unpack(List(group.commands):map(add_command)))
end

parser:parse()
