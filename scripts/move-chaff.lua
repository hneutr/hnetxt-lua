local Path = require("hl.Path")
local List = require("hl.List")
local Dict = require("hl.Dict")

local db = require("htl.db")
db.get()
local mirrors = require("htl.db.mirrors")
local projects = require("htl.db.projects")
local Config = require("htl.Config")

local updates = List()
projects:get():foreach(function(project)
    local made_changes = false
    local new_conf = mirrors:get_absolute_config()
    mirrors:get_project_config(project.path).mirrors:foreach(function(kind, old_dir)
        local new_dir = new_conf[kind]

        if not new_dir:exists() then
            new_dir:mkdir()
        end

        if old_dir:exists() then
            old_dir:iterdir({dirs = false}):foreach(function(old_path)
                local new_path = new_dir:join(old_path:relative_to(old_dir))
                
                new_path:write(old_path:read())
                old_path:unlink()
                made_changes = true
            end)
        end
    end)

    if made_changes then
        print(project.path)
    end
end)
