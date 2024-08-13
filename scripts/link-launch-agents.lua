io = require("hl.io")

local Path = require("hl.Path")
local List = require("hl.List")

local hnetxt_agents_dir = Path.home:join("lib", "hnetxt-lua", "scripts", "launch-agents")
local hne_agents_dir = Path.home:join("Library", "LaunchAgents")

hnetxt_agents_dir:iterdir():foreach(function(source)
    local target = hne_agents_dir:join(source:name())

    if not target:exists() then
        io.command(string.format("ln -s %s %s", source, target))
    end

    io.command(string.format("launchctl load %s", target))
end)
