--[[
functions:

- Project:
    - static:
        - TODO: in_project: checks whether the cwd is in a `.project` dir
        - get_config_path: get the path where a config would be in a given dir
    - on object:
        - TODO: root: returns the project root
        - TODO: journal: returns the project journal
        - TODO: config: returns the project config
    - unclear:
    - `create`:
        - TODO: probably make into an `on object` method
        - TODO: update the "project name to path" database (`register`)


--]]

local lyaml = require("lyaml")
local Object = require("hneutil.object")
local Path = require("hneutil.path")
local Config = require("hnetxt-lua.config")

table = require("hneutil.table")
string = require("hneutil.string")

local Project = Object:extend()

function Project.get_config_path(dir)
    return Path.joinpath(dir or Path.cwd(), Config.get("project").filename)
end

function Project.create(args)
    args = table.default(args, {metadata = {start_date = os.date("%Y%m%d")}})
    config_path = Project.get_config_path(args.dir)
    Path.write(config_path, lyaml.dump({args.metadata}))
end

function Project.in_project()
end

return Project
