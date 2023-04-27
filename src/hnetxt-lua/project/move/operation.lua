local Object = require("hneutil.object")
local Config = require("hnetxt-lua.config")
local Path = require('hneutil.path')

local Location = require("hnetxt-lua.text.location")
local Mark = require("hnetxt-lua.text.mark")
local Mirror = require("hnetxt-lua.project.mirror")

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
                                        maybe don't implement due to complexity

add "mirrors" behavior:
- default to "move"
- have "file → mark" implement "combine"


IMPORTANT:
distinguish between processing types:
- "do": eg move file a to file b
- "update": eg make references to a into references to b

----------------------------------------
--]]
local Operation = Object:extend()
Operation.dir_file_name = Config.get("directory_file").name

Operation.defaults = {
    check_a = function(a, b) return false end,
    check_b = function(b, a) return false end,
    transform_b = function(b, a) return b end,
    map_a_to_b = function(a, b) return {[a] = b} end,
    -- process = function(map) end,
    -- get_mirrors = function() end,
    -- process_mirrors = function(mirrors) end,
}

function Operation.file_is_dir_file(p)
    return Path.name(p) == Operation.dir_file_name
end

function Operation.dir_file(p)
    return Path.joinpath(p, Operation.dir_file_name)
end

local FileOperation = Operation:extend()
FileOperation.defaults = {
    check_a = Path.is_file,
}

local DirOperation = Operation:extend()
function DirOperation.map_paths_from_dir_to_dir(a, b)
    local map = {}
    for _, a_path in ipairs(Path.iterdir(a)) do
        map[a_path] = Path.joinpath(b, Path.relative_to(a_path, a))
    end
    return map
end

DirOperation.defaults = {
    check_a = Path.is_dir,
    map_a_to_b = DirOperation.map_paths_from_dir_to_dir,
}

local MarkOperation = Operation:extend()


MarkOperation.defaults = {
    check_a = Location.str_has_label,
    --[[
    default:
        do:
            1. content = remove_mark_content_from_file(a.md, b)
            2. add_mark_content_to_file(b.md, content, b)
        references:
            {a.md:b = c.md}

    remove_mark_content_from_file(file, mark):
        1. content = Path.read(file)
        2. content, mark_content  = remove_mark_content_from(content, mark)
        3. Path.write(file, content)
        4. return mark_content

    add_mark_content_to_file(file, new_mark_content, mark, include_header=false):
        1. content = Path.read(file)
        2. before, mark_content, after = partition_mark_content(content, mark)
            - if mark_content:len() > 0:
                - mark_content += new_mark_content
            - else:
                - if include_header:
                    - after += Header(mark)
                - after += new_mark_content
        3. Path.write(before .. mark_content .. after)
    ]]
}

local operations = {
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
        -- TODO
        -- a.md → b.md?:c = b.md:c
        -- maybe don't implement due to complexity
        -- to_mark = {
        --     check_b = Location.str_has_label,
        --[[
            file:move + create mark, append text + combine mirrors
            do:
                 - map:
                     - {a = b}
                     - for each x type mirror of a {a:get_mirror_path(x) = b:get_mirror_path(x)}
                 - for each a, b in map:
                     1. update b:
                          - Path.read(b)
                          - Header({size = "large", content = "c"})
                          - Path.read(a)
                          - Path.write(b)
                     2. Path.unlink(a)
            references:
                 - files:
                     - map:
                         - {a.md = b.md:c}
                         - for each x type mirror of a {a:get_mirror_path(x) = b:get_mirror_path(x)}
                 - marks:
                     - for each reference x in a.md in files.map {a.md:x = b.md:x}
        ]]
        -- },
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
            --[[
            do:
                1. content = remove_mark_content_from_file(a.md, b)
                2. add_mark_content_to_file(c.md, content, d, include_header=true)
            references:
                {a.md:b = c.md:d}
            ]]
        }
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

local DirectoryCase = FileCase:extend()
DirectoryCase.path_check = Path.is_dir_like

function DirectoryCase.mapper(a, b)
    local map = {}
    for _, a_path in ipairs(Path.iterdir(a)) do
        map[a_path] = Path.joinpath(b, Path.relative_to(a_path, a))
    end
    return map
end

