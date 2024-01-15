local Yaml = require("hl.yaml")
local Dict = require("hl.Dict")
local Path = require("hl.path")
local Util = require("htc.util")
local Colors = require("htc.colors")

local Project = require("htl.project")
local Registry = require("htl.project.registry")

local args = {
    new_project = {"project", default = Path.name(Path.cwd()), args = "1"},
    project = {"project", description = "project name", default = Util.default_project(), args = "1"},
    dir = {"-d --dir", default = Path.cwd(), description = "project directory"},
}

return {
    require_command = false,
    action = function(args)
        if #Dict(args):keys() == 1 then
            Registry.get():keys():sorted():foreach(function(name)
                print(Project(name).metadata.name)
            end)
        end
    end,
    commands = {
        create = {
            args.new_project,
            {"-d --date", default = os.date("%Y%m%d")},
            args.dir,
            action = function(args)
                Project.create(args.project, args.dir, {date = args.date})
            end,
        },
        register = {
            args.new_project,
            args.dir,
            action = function(args) Registry.set_entry(args.project, args.dir) end,
        },
        deregister = {
            args.new_project,
            action = function(args) Registry.set_entry(args.project, nil) end,
        },
        root = {
            args.project,
            action = function(args) print(Project(args.project).root) end,
        },
    }
}
