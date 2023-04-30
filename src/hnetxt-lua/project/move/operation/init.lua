local Object = require("hneutil.object")
local Config = require("hnetxt-lua.config")
local Path = require('hneutil.path')

local Mirror = require("hnetxt-lua.project.mirror")
local Location = require("hnetxt-lua.text.location")
local Reference = require("hnetxt-lua.text.reference")

--------------------------------------------------------------------------------
--                                 Operation                                  --
--------------------------------------------------------------------------------
local Operation = Object:extend()
Operation.dir_file_name = Config.get("directory_file").name

function Operation.check_source(source, target) return true end
function Operation.check_target(target, source) return true end
function Operation.transform_target(target, source) return target end
function Operation.map_source_to_target(source, target) return {[source] = target} end
function Operation.map_mirrors(map)
    local mirrors_map = {}
    for source, target in pairs(map) do
        mirrors_map = table.default(mirrors_map, Mirror.find_updates(source, target))
    end
    return mirrors_map
end
function Operation.process(map, mirrors_map)
    map = table.default({}, map or {}, mirrors_map or {})
    for source, target in pairs(map) do
        Path.rename(source, target)
    end
end
--[[
should handle both files and locations
- for each file in map + mirrors_map: point `source` references at `target`
    - for each mark in the file: point `source:mark` references at `target:mark`

- maybe have an option to look for marks in the file or not?
--]]
--[[
    - files:
    - map:
        - {a.md = b.md:c}
        - for each x type mirror of a {a:get_mirror_path(x) = b:get_mirror_path(x)}
    - marks:
        - for each reference x in a.md in files.map {a.md:x = b.md:x}
]]
    -- TODO!!!!!!
    -- - marks:
    --     - for each reference x in a.md in files.map {a.md:x = b.md:x}
function Operation.update_references(map, mirrors_map)
    -- map = table.default({}, map or {}, mirrors_map or {})
end

function Operation.is_mark(p)
    return Location.str_has_label(p)
end

function Operation.could_be_file(p)
    return Path.is_file_like(p) and not Operation.is_mark(p)
end

function Operation.could_be_dir(p)
    return Path.is_dir_like(p) and not Path.exists(p) and not Operation.is_mark(p)
end

function Operation.is_dir_file_of(p)
    return Path.name(p) == Operation.dir_file_name
end

function Operation.dir_file_of(p)
    return Path.joinpath(p, Operation.dir_file_name)
end


function Operation.dir_is_not_parent_of(p1, p2)
    return Path.is_dir(p1) and not Path.is_relative_to(p2, p1)
end

function Operation.is_parent_of(p1, p2)
    return p1 == Path.parent(p2)
end

function Operation.make_parent_of(p1, p2)
    return Path.joinpath(p1, Path.name(p2))
end

function Operation:new(args)
    for k, v in pairs(args or {}) do
        self[k] = v
    end
end

function Operation:applies(source, target)
    return self.check_source(source, target) and self.check_target(target, source)
end

function Operation:operate(source, target, args)
    args = table.default(args, {process = false, update = true})

    target = self.transform_target(target, source)
    local map = self.map_source_to_target(a, b)
    local mirrors_map = self.map_mirrors(map)

    if args.process then
        self.process(map, mirrors_map)
    end

    if args.update then
        self.update_references(map, mirrors_map)
    end

    return nil
end

return Operation
