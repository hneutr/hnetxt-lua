local Object = require("hneutil.object")
local Config = require("hnetxt-lua.config")
local Path = require('hneutil.path')

local Inferrer = Object:extend()
Inferrer.dir_file_name = Config.get("directory_file").name
Inferrer.suffix = '.md'

--------------------------------------------------------------------------------
--                                  FileCase                                  --
--------------------------------------------------------------------------------
local FileCase = Object:extend()
FileCase.cases = {
    -- a.md → b.md? = b.md
    rename = {
        check = function(a, b) return Path.is_file_like(b) end,
    },
    -- a.md → b = b/a.md
    move = {
        check = function(a, b) return Path.is_dir(b) end,
        transform = function(a, b) return Path.joinpath(b, Path.name(a)) end,
    },
    -- a.md → a! = a/@.md
    to_dir = {
        check = function(a, b) return Path.is_dir_like(b) and not Path.exists(b) and Path.stem(a) == b end,
        transform = function(a, b) return Path.joinpath(b, Inferrer.dir_file_name) end,
    },
}

FileCase.defaults = {
    transform = function(a, b) return b end,
    remapper = function(a, b, map) return map end,
}
FileCase.path_check = Path.is_file_like

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
        check = function(a, b) return Path.is_dir_like(b) and not Path.exists(b) end,
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
DirectoryCase.path_check = Path.is_dir_like

function DirectoryCase.mapper(a, b)
    local map = {}
    for _, a_path in ipairs(Path.iterdir(a)) do
        map[a_path] = Path.joinpath(b, Path.relative_to(a_path, a))
    end
    return map
end

-- TODO: also check for file:mark stuff!

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
}
