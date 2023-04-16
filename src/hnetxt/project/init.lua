--[[
functions:
- in_project: checks whether the cwd is in a `.project` dir

- Project:
    TODO: 
    - `create`: update the "project name to path" database

    - root: returns the project root
    - journal: returns the project journal
    - config: returns the project config

--]]

local Object = require("hneutil.object")
local Path = require("hneutil.path")
local lyaml = require("lyaml")
table = require("hneutil.table")
string = require("hneutil.string")

local Project = Object:extend()

Project.constants_path = Path.joinpath(Path.home(), ".config/hnetxt/project/constants.yaml")

function Project.load_constants()
    return lyaml.load(Path.read(Project.constants_path))
end

function Project.in_project()
end

function Project.get_config_path(dir)
    return Path.joinpath(dir or Path.cwd(), Project.load_constants().filename)
end

function Project.create(args)
    args = table.default(args, {metadata = {start_date = os.date("%Y%m%d")}})
    config_path = Project.get_config_path(args.dir)
    Path.write(config_path, lyaml.dump({args.metadata}))
end

return Project
