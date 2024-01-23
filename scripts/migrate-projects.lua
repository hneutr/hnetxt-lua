local Yaml = require('hl.yaml')
local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.Path")

local Config = require("htl.config")

local db = require("htl.db")
local projects = db.get()['projects']

Dict(Yaml.read(Config.data_dir:join("projects", "registry.yaml"))):foreach(function(title, path)
    path = Path(path)
    if not projects:where({title = title}) then
        local project = {title = title, path = path}

        local project_config = path:join(".project")
        if project_config:exists() then
            project.created = Yaml.read(project_config).date
        end

        projects:insert(project)
    end
end)

projects:get():foreach(function(p)
    print(projects.tostring(p))
end)
