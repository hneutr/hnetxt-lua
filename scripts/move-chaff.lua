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
    local root = project.path

    local old_scratch_dir = mirrors:get_project_config(root).mirrors.scratch

    if old_scratch_dir:exists() then
        old_scratch_dir:iterdir({dirs = false}):sorted(function(a, b)
            return tostring(a) < tostring(b)
        end):foreach(function(old_path)
            local new_path = Config.paths.data_dir:join(old_path:relative_to(root))

            -- new_path:parent():mkdir()
            -- old_path:rename(new_path)

            -- if mirrors:where({path = new_path}) then
            --     mirrors:update({
            --         -- where = {path = tostring(new_path)},
            --         -- set = {path = tostring(old_path)},
            --     })
            -- end
            
            -- updates:append({old = old_path, new = new_path})
        end)
    end
    -- updates:foreach(function(u)
    --     print(string.format("%s: %s", u.old, u.new))
    -- end)
    os.exit()
end)


-- mirrors:get({where = {kind = "scratch"}}):foreach(function(mirror)
--     print(mirror.path)
-- end)
