io = require("hl.io")

local Path = require("hl.Path")
local List = require("hl.List")

local hnetxt_agents_dir = Path.home:join("lib", "hnetxt-lua", "scripts", "launch-agents")
local hne_agents_dir = Path.home:join("Library", "LaunchAgents")

hnetxt_agents_dir:iterdir():foreach(function(source_path)
    local target_path = hne_agents_dir:join(source_path:name())
    print(source_path)
    print(target_path)
end)
