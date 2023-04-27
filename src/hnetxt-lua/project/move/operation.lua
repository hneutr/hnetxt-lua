local Object = require("hneutil.object")
local Config = require("hnetxt-lua.config")
local Path = require('hneutil.path')

local Location = require("hnetxt-lua.text.location")
local Mark = require("hnetxt-lua.text.mark")
local Mirror = require("hnetxt-lua.project.mirror")
local Parser = require("hnetxt-lua.parse")

--[[
--------------------------------------------------------------------------------
notation:
    - `a.md`: there is a file named "a.md"
    - `a`: there is a directory named "a"
    - `a!`: a doesn't exist
    - `a?`: exists or doesn't
behaviors:
    file →:
        - a.md     → b.md?   = b.md   | rename
        - a.md     → b       = b/a.md | move
        - a.md     → a!      = a/@.md | to dir
    dir →:
        - a        → b!      = b      | rename
        - a        → c       = c/a    | move
        - a/b      → a       = a/*    | to files
          a/b/@.md           = a/b.md
          a/b/c.md           = a/c.md
    mark → file:
        - a.md:b   → c.md?   = c.md   | file:move + remove mark, append text
    mark → dir:
        - a.md:b   → c!      = c/@.md | file:to dir + remove mark, append text
        - a.md:b   → c       = c/b.md | file:move + remove mark, append text
    mark → mark:
        - a.md:b   → c.md?:d = c.md:d | file:move + modify mark, append text
    file → mark:
        - a.md     → b.md?:c = b.md:c | file:move + create mark, append text + combine mirrors
--]]


--------------------------------------------------------------------------------
--                                 Operation                                  --
--------------------------------------------------------------------------------
local Operation = Object:extend()
Operation.dir_file_name = Config.get("directory_file").name

function Operation.check_a(a, b) return true end
function Operation.check_b(b, a) return true end
function Operation.transform_b(b, a) return b end
function Operation.map_a_to_b(a, b) return {[a] = b} end
function Operation.map_mirrors(map)
    local mirrors_map = {}
    for a, b in pairs(map) do
        mirrors_map = table.default(mirrors_map, Mirror.find_updates(a, b))
    end
    return mirrors_map
end
function Operation.process(map, mirrors_map)
    map = table.default(map, mirrors_map)
    for a, b in pairs(map) do
        Path.rename(a, b)
    end
end
function Operation.update_references(map, mirrors_map)
    -- TODO!!!!!!
end

function Operation.file_is_dir_file(p) return Path.name(p) == Operation.dir_file_name end
function Operation.dir_file(p) return Path.joinpath(p, Operation.dir_file_name) end

function Operation:new(args)
    self = table.default(self, args or {})
end

function Operation:applies(a, b)
    return self.check_a(a, b) and self.check_b(b, a)
end

function Operation:evaluate(a, b, args)
    args = table.default(args, {process = false, update = true})

    b = self.transform_b(b, a)
    local map = self.map_a_to_b(a, b)
    local mirrors_map = self.map_mirrors(map)

    if args.process then
        self.process(map, mirrors_map)
    end

    if args.update then
        self.update_references(map, mirrors_map)
    end

    return nil
end

--------------------------------------------------------------------------------
--                               FileOperation                                --
--------------------------------------------------------------------------------
local FileOperation = Operation:extend()
FileOperation.check_a = Path.is_file

--------------------------------------------------------------------------------
--                            FileToMarkOperation                             --
--------------------------------------------------------------------------------
local FileToMarkOperation = FileOperation:extend()
FileToMarkOperation.check_b = Location.str_has_label
function FileToMarkOperation.map_mirrors(map)
    local mirrors_map = {}
    for a, b in pairs(map) do
        -- mirrors just point to the mirror of the file
        b = Location.from_str(b).path
        mirrors_map = table.default(mirrors_map, Mirror.find_updates(a, b))
    end
    return mirrors_map
end
function FileToMarkOperation.process(map, mirrors_map)
    local parser = Parser()
    for a, b in pairs(map) do
        parser:add_mark_content({
            new_content = Path.readlines(a),
            from_mark_location = Location.from_str(a),
            to_mark_location = Location.from_str(b),
            include_mark = true,
        })

        Path.unlink(a)

    for a, b in pairs(mirrors_map) do
        local line_sets = {Path.readlines(a)}

        if Path.exists(b) then
            line_sets[#line_sets + 1] = Path.readlines(b)
        end

        Path.write(b, Parser.merge_line_sets(line_sets))
        Path.unlink(a)
    end
end
function FileToMarkOperation.update_references(map, mirrors_map)
--[[
    - files:
    - map:
        - {a.md = b.md:c}
        - for each x type mirror of a {a:get_mirror_path(x) = b:get_mirror_path(x)}
    - marks:
        - for each reference x in a.md in files.map {a.md:x = b.md:x}
]]
end


--------------------------------------------------------------------------------
--                                DirOperation                                --
--------------------------------------------------------------------------------
local DirOperation = Operation:extend()
DirOperation.check_a = Path.is_dir
function DirOperation.map_a_to_b(a, b)
    -- makes a map path of paths in a relative to b
    local map = {}
    for _, a_path in ipairs(Path.iterdir(a)) do
        map[a_path] = Path.joinpath(b, Path.relative_to(a_path, a))
    end
    return map
end

--------------------------------------------------------------------------------
--                               MarkOperation                                --
--------------------------------------------------------------------------------
local MarkOperation = Operation:extend()
MarkOperation.check_a = Location.str_has_label
function MarkOperation.map_mirrors() return {} end
function MarkOperation.process(map)
    -- this moves the marks in a to b
    if include_mark == nil then
        include_mark = true
    end

    local parser = Parser()

    for a, b in pairs(map) do
        local a_location = Location.from_str(a)
        local b_location = Location.from_str(b)

        parser:add_mark_content({
            new_content = parser:remove_mark_content(a_location),
            from_mark_location = a_location,
            to_mark_location = b_location,
            include_mark = include_mark,
        })
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                  Operator                                  --
--                                                                            --
--------------------------------------------------------------------------------
local Operator = Object:extend()
function Operator:new(args)
    self = table.default(self, args or {}, self.defaults)
end

-- function Operation:

function Operator.evaluate_cases(a, b)
    local CaseClass = FileCase.get_case_class(a)

    for name, case_info in pairs(CaseClass.cases) do
        local result = CaseClass(case_info):evaluate(a, b)

        if result then
            return result
        end
    end
end

function Operator.get_case_class(a, b)
    local classes = {FileCase, DirectoryCase}
    for _, CaseClass in ipairs(classes) do
        if CaseClass.path_check(path) then
            return CaseClass
        end
    end
end

Operator.string_to_class = {
    file = FileOperation,
    dir = DirOperation,
    mark = MarkOperation,
    file_to_dir = FileToMarkOperation,
}

Operation.Operations = {
    file = {
        -- a.md → b.md? = b.md
        rename = {
            check_b = Path.is_file_like,
        },
        -- a.md → b = b/a.md
        move = {
            check_b = Path.is_dir,
            transform_b = function(b, a) return Path.joinpath(b, Path.name(a)) end,
        },
        -- a.md → b! = a/@.md
        to_dir = {
            check_b = function(b) return Path.is_dir_like(b) and not Path.exists(b) end,
            transform_b = Operation.get_dir_file,
        },
        -- a.md → b.md?:c = b.md:c
        to_mark = {
            check_b = Location.str_has_label,
            map_mirrors = FileToMarkOperation.map_mirrors,
            process = FileToMarkOperation.process,
        },
    },
    dir = {
        -- a → b! = b
        rename = {
            check_b = function(b) return Path.is_dir_like(b) and not Path.exists(b) end,
        },
        -- a → c = c/a
        move = {
            check_b = function(b, a) return Path.is_dir(b) and not Path.is_relative_to(b, a) end,
            transform_b = function(b, a) return Path.joinpath(b, Path.name(a)) end,
        },
        -- a/b → a  = a/*
        -- a/b/@.md = a/b.md
        -- a/b/c.md = a/c.md
        to_files = {
            check_b = function(b, a) return b == Path.parent(a) end,
            map_a_to_b = function(a, b)
                local map = DirOperation.map_paths_from_dir_to_dir(a, b)
                local a_dir_file = Operation.dir_file(a)
                local b_dir_file = map[a_dir_file]

                if b_dir_file then
                    map[a_dir_file] = Path.with_stem(b_dir_file, Path.name(a))
                end

                return map
            end
        },
    },
    mark = {
        -- a.md:b → c.md? = c.md
        to_file = {
            check_b = Path.is_file_like,
        },
        -- a.md:b → c/b.md
        to_dir_file = {
            check_b = Path.is_dir,
            transform_b = function(b, a) return Path.joinpath(b, Location.from_str(a).label + '.md') end,
        },
        -- a.md:b → c! = c/@.md
        to_dir = {
            check_b = function(b) return Path.is_dir_like(b) and not Path.exists(b) end,
            transform_b = Operation.get_dir_file,
        },
        -- a.md:b → c.md?:d = c.md:d
        to_mark = {
            check_b = Location.str_has_label,
        },
    },
}

return {
    Operator = Operator,
    Operation = Operation,
    FileOperation = FileOperation,
    DirOperation = DirOperation,
    MarkOperation = MarkOperation,
    FileToMarkOperation = FileToMarkOperation,
}
