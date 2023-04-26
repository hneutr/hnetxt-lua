local Object = require("hneutil.object")
local Config = require("hnetxt-lua.config")
local Path = require('hneutil.path')

local DIR_FILE_NAME = Config.get("directory_file").name

local Inferrer = Object:extend()
Inferrer.dir_file_name = Config.get("directory_file").name
Inferrer.suffix = '.md'

function liberal_is_file(p)
    return Path.suffix(p):len() > 0
end

function liberal_is_dir(p)
    return Path.suffix(p):len() == 0
end

--------------------------------------------------------------------------------
--                                  FileCase                                  --
--------------------------------------------------------------------------------
local FileCase = Object:extend()
FileCase.cases = {
    -- a.md → b.md? = b.md
    rename = {
        check = function(a, b) return liberal_is_file(b) end,
    },
    -- a.md → b = b/a.md
    move = {
        check = function(a, b) return Path.is_dir(b) end,
        transform = function(a, b) return Path.joinpath(b, Path.name(a)) end,
    },
    -- a.md → a! = a/@.md
    to_dir = {
        check = function(a, b) return liberal_is_dir(b) and not Path.exists(b) and Path.stem(a) == b end,
        transform = function(a, b) return Path.joinpath(b, Inferrer.dir_file_name) end,
    },
}

FileCase.defaults = {
    transform = function(a, b) return b end,
    remapper = function(a, b, map) return map end,
}
FileCase.path_check = liberal_is_file

function FileCase.mapper(a, b) return {[a] = b} end

function FileCase:new(args)
    self = table.default(self, args or {}, self.defaults)
end

function FileCase:evaluate(a, b)
    if self.path_check(a) and self.check(a, b) then
        b = self.transform(a, b)
        local map = self.mapper(a, b)
        return self.remapper(a, b, map)
    end

    return nil
end

function FileCase.evaluate_cases(a, b)
    local CaseClass = FileCase.get_case_class(a)

    for name, case_info in pairs(CaseClass.cases) do
        local result = CaseClass(case_info):evaluate(a, b)

        if result then
            return result
        end
    end
end

--------------------------------------------------------------------------------
--                               DirectoryCase                                --
--------------------------------------------------------------------------------
local DirectoryCase = FileCase:extend()
DirectoryCase.cases = {
    -- a → b! = b
    rename = {
        check = function(a, b) return liberal_is_dir(b) and not Path.exists(b) end,
    },
    -- a → c = c/a
    move = {
        check = function(a, b) return Path.is_dir(b) end,
        transform = function(a, b) return Path.joinpath(b, Path.name(a)) end,
    },
    -- a/b → a  = a/*
    -- a/b/@.md = a/b.md
    -- a/b/c.md = a/c.md
    to_files = {
        check = function(a, b) return Path.parent(a) == b end,
        transform = function(a, b) return Path.parent(a) end,
        map = function(a, b)
            local map = Inferrer.map_paths_from_dir_to_dir(a, b)
            local a_dir_file = Path.joinpath(a, Inferrer.dir_file_name)
            local b_dir_file = map[a_dir_file]

            if b_dir_file then
                map[a_dir_file] = Path.with_stem(b_dir_file, Path.name(a))
            end

            return map
        end
    },
}
DirectoryCase.path_check = liberal_is_dir

function DirectoryCase.mapper(a, b)
    local map = {}
    for _, a_path in ipairs(Path.iterdir(a)) do
        map[a_path] = Path.joinpath(b, Path.relative_to(a_path, a))
    end
    return map
end

-- TODO: also check for file:mark stuff!

--------------------------------------------------------------------------------
-- Inferrer
-- --------
--[[
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
        - a.md     → b.md?:a = b.md:a | file:move + create mark, append text + combine mirrors
                                        maybe don't implement due to complexity


add "mirrors" behavior:
- default to "move"
- have "file → mark" implement "combine"

----------------------------------------

for mark movement:
- for source:
    - get mark content: find header, continue to next header/divider of same or greater level
- for target:
    - rename mark

- when moving a mark to a file: remove the header content

--]]
--------------------------------------------------------------------------------
function Inferrer:new(a, b)
    self.a = Path.resolve(a)
    self.b = Path.resolve(b)
end

function Inferrer.get_case_class(path)
    local classes = {FileCase, DirectoryCase}
    for _, CaseClass in ipairs(classes) do
        if CaseClass.path_check(path) then
            return CaseClass
        end
    end
end


return {
    Inferrer = Inferrer,
    FileCase = FileCase,
    DirectoryCase = DirectoryCase,
    liberal_is_file = liberal_is_file,
    liberal_is_dir = liberal_is_dir,
}
