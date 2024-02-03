local Dict = require("hl.Dict")
local Path = require('hl.path')
local Config = require("htl.config")

local Location = require("htl.text.location")
local Reference = require("htl.text.reference")

--------------------------------------------------------------------------------
--                                 Operation                                  --
--------------------------------------------------------------------------------
local M = {}
M.dir_file_name = Config.get("directory_file").name

function M.check_source(source, target) return true end
function M.check_target(target, source) return true end
function M.transform_target(target, source) return target end
function M.map_source_to_target(source, target) return {[source] = target} end
function M.move(map) end
function M.update_references(map, dir)
    Reference.update_locations(Dict.from(map or {}), dir)
end

function M.remove(path)
    if Path.is_dir(path) then
        Path.rmdir(path, true)
    else
        Path.unlink(path)
    end
end

function M.could_be_file(p)
    return Path.is_file_like(p)
end

function M.could_be_dir(p)
    return Path.is_dir_like(p) and not Path.exists(p)
end

function M.is_dir_file_of(p)
    return Path.name(p) == M.dir_file_name
end

function M.is_nil(p)
    return p == nil
end

function M.dir_file_of(p)
    return Path.join(p, M.dir_file_name)
end

function M.dir_is_not_parent_of(p1, p2)
    return Path.is_dir(p1) and not Path.is_relative_to(p2, p1)
end

function M.is_parent_of(p1, p2)
    return p1 == Path.parent(p2)
end

function M.make_parent_of(p1, p2)
    return Path.join(p1, Path.name(p2))
end

return M
