local Object = require("hl.object")
local Path = require('hl.path')
local Config = require("htl.config")

local Mirror = require("htl.project.mirror")
local Location = require("htl.text.location")
local Reference = require("htl.text.reference")

--------------------------------------------------------------------------------
--                                 Operation                                  --
--------------------------------------------------------------------------------
local M = {}
M.dir_file_name = Config.get("directory_file").name
M.is_mark = Location.str_has_label

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
function M.move(map, mirrors_map) end
function M.update_references(map, mirrors_map, dir)
    Reference.update_locations(table.default({}, map or {}, mirrors_map or {}), dir)
end

function M.remove(source)
    local paths = {source}
    for _, path in pairs(paths) do
        for _, mirror_path in ipairs(Mirror.get_all_mirrored_paths(path)) do
            Path.unlink(mirror_path)
        end

        if Path.is_dir(path) then
            Path.rmdir(path, true)
        else
            Path.unlink(path)
        end
    end
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

function M.is_nil(p)
    return p == nil
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
