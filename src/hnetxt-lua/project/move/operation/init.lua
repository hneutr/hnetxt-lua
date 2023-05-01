local Object = require("hneutil.object")
local Config = require("hnetxt-lua.config")
local Path = require('hneutil.path')

local Project = require("hnetxt-lua.project")
local Mirror = require("hnetxt-lua.project.mirror")
local Location = require("hnetxt-lua.text.location")
local Reference = require("hnetxt-lua.text.reference")

--------------------------------------------------------------------------------
--                                 Operation                                  --
--------------------------------------------------------------------------------
local M = {}
M.dir_file_name = Config.get("directory_file").name

function M.check_source(source, target) return true end
function M.check_target(target, source) return true end
function M.transform_target(target, source) return target end
function M.map_source_to_target(source, target) return {[source] = target} end
function M.map_mirrors(map)
    local mirrors_map = {}
    for source, target in pairs(map) do
        mirrors_map = table.default(mirrors_map, Mirror.find_updates(source, target))
    end

    for source, target in pairs(map) do
        mirrors_map[source] = nil
    end

    return mirrors_map
end
function M.process(map, mirrors_map) end
function M.update_references(map, mirrors_map, dir)
    Reference.update_locations(table.default({}, map or {}, mirrors_map or {}), dir)
end

function M.is_mark(p)
    return Location.str_has_label(p)
end

function M.could_be_file(p)
    return Path.is_file_like(p) and not M.is_mark(p)
end

function M.could_be_dir(p)
    return Path.is_dir_like(p) and not Path.exists(p) and not M.is_mark(p)
end

function M.is_dir_file_of(p)
    return Path.name(p) == M.dir_file_name
end

function M.dir_file_of(p)
    return Path.joinpath(p, M.dir_file_name)
end


function M.dir_is_not_parent_of(p1, p2)
    return Path.is_dir(p1) and not Path.is_relative_to(p2, p1)
end

function M.is_parent_of(p1, p2)
    return p1 == Path.parent(p2)
end

function M.make_parent_of(p1, p2)
    return Path.joinpath(p1, Path.name(p2))
end

return M
