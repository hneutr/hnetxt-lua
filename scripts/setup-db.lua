local Yaml = require('hl.yaml')
local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.Path")

local Config = require("htl.config")

local db = require("htl.db")
local projects = db.get()['projects']
local urls = db.get()['urls']

local stats = Dict()
function set_stats(key)
    stats[key] = Dict({
        projects = #projects:get(),
        urls = #urls:get(),
    })
end

function set_diff()
    stats.diff = Dict({
        projects = stats['end'].projects - stats.start.projects,
        urls = stats['end'].urls - stats.start.urls,
    })
end

set_stats("start")

Dict(Yaml.read(Config.data_dir:join("projects", "registry.yaml"))):foreach(function(title, path)
    path = Path(path)
    if path:exists() and not projects:where({title = title}) then
        local project = {title = title, path = path}

        local project_config = path:join(".project")
        if project_config:exists() then
            project.created = Yaml.read(project_config).date
        end

        projects:insert(project)
    end
end)

projects:get():foreach(function(project)
    urls:remove({project = project.title})
    project.path:iterdir({dirs = false}):foreach(function(path)
        urls:insert({path = path, project = project.title, resource_type = "file"})
    end)
end)

set_stats("end")
set_diff()

List({"start", "end", "diff"}):foreach(function(key)
    print(key .. ":")
    stats[key]:foreach(function(k, v)
        print(string.format("  %s: %d", k, v))
    end)
end)
