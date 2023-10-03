--[[
unimplemented implement:
- pathlib (python):
    - glob
    - rglob
    - absolute: PATH.abspath
    - link_to
    - readlink
    - symlink_to
- lua-path:
    - PATH.chdir
    - PATH.dirname
    - PATH.normalize
    - PATH.splitext
    - PATH.splitpath
    - PATH.split
    - PATH.splitroot
    - PATH.isfullpath
    - PATH.isabs
    - PATH.fullpath
    - PATH.islink
    - PATH.copy
--]]

local class = require("pl.class")

local lfs = require('lfs')
local PATH = require("path")

local Dict = require("hl.Dict")
local List = require("hl.List")
local Set = require("pl.Set")

string = require("hl.string")

class.Path()

Path.sep = "/"

function Path.as_string(p)
    if p ~= nil and type(p) ~= 'string' then
        p = tostring(p)
    end

    return p
end

function Path.as_path(p)
    if p ~= nil and Path.is_a(p) ~= Path then
        p = Path(p)
    end

    return p
end

function Path.make_fn_match_input(fn)
    return function(p, ...)
        local transform = Path.as_path

        if type(p) == 'string' then
            transform = Path.as_string
        end

        return transform(fn(p, ...))
    end
end

function Path.make_list_fn_match_input(fn)
    return function(p, ...)
        local transformer = Path.as_path

        if type(p) == 'string' then
            transformer = Path.as_string
        end

        return fn(p, ...):transform(transformer)
    end
end

List({
    "startswith",
    "endswith",
    "split",
}):foreach(function(fn)
    Path[fn] = function(p, ...)
        return string[fn](Path.as_string(p), ...)
    end
end)


function Path:_init(path)
    self.p = Path.as_string(path)
end

function Path:__concat(p)
    return self:join(p)
end

function Path:__tostring()
    return self.p
end

function Path.__eq(p1, p2)
    return Path.as_string(p1) == Path.as_string(p2)
end

function Path.is_file(p)
    return PATH.isfile(Path.as_string(p)) and true
end

function Path.is_dir(p)
    return PATH.isdir(Path.as_string(p)) and true
end

function Path.exists(p)
    return PATH.exists(Path.as_string(p)) and true
end

function Path.is_empty(p)
    return PATH.isempty(Path.as_string(p)) and true
end

function Path.mkdir(p)
    PATH.mkdir(Path.as_string(p))
end

function Path.unlink(p)
    PATH.remove(Path.as_string(p))
end

function Path.parts(p)
    local parts = List(p:split(Path.sep)):filter(function(part)
        return #part > 0
    end)

    if p:startswith(Path.sep) then
        parts:put(Path.sep)
    end

    return parts
end

function Path.read(p)
    local fh = io.open(Path.as_string(p), "r")
    local content = fh:read("*a")
    fh:close()
    return content
end

function Path.readlines(p)
    return Path.read(p):splitlines()
end

function Path.write(p, content)
    p = Path.as_path(p)

    if not p:parent():exists() then
        p:parent():mkdir()
    end

    content = List.as_list(content)
    content:transform(tostring)

    local fh = io.open(tostring(p), "w")
    fh:write(content:join("\n"))
    fh:close()
end

function Path.touch(p)
    p = Path.as_path(p)
    if not p:exists() then
        p:write("")
    end
end

Path.removesuffix = Path.make_fn_match_input(function(p, suffix)
    return string.removesuffix(Path.as_string(p), suffix)
end)

Path.removeprefix = Path.make_fn_match_input(function(p, prefix)
    return string.removeprefix(Path.as_string(p), prefix)
end)

Path.expanduser = Path.make_fn_match_input(function(p)
    if p:startswith("~") then
        return Path.home:join(p:removeprefix("~"))
    end

    return p
end)

function Path.rename(source, target)
    source = Path.as_string(source)
    target = Path.as_string(target)

    if Path.is_file(source) then
        PATH.rename(source, target, true)
    elseif Path.is_dir(source) then
        os.rename(source, target)

        if source ~= target then
            Path(source):rmdir(true)
        end
    end
end

Path.join = Path.make_fn_match_input(function(p, p2, ...)
    p = Path.as_string(p)
    p2 = Path.as_string(p2)

    if p ~= Path.sep then
        p = p:removesuffix(Path.sep)
    end

    p2 = p2:removeprefix(Path.sep)

    if #p2 > 0 then
        if p == Path.sep then
            p = p .. p2
        else
            p = string.join(Path.sep, {p, p2})
        end
    end

    if ... then
        p = Path.join(p, ...)
    end

    return p
end)

Path.joinpath = Path.join

Path.parents = Path.make_list_fn_match_input(function(p)
    local parts = Path.parts(p)
    parts:pop()

    local parents = List()
    for _, part in ipairs(parts:reverse()) do
        part = Path(part)
        parents:transform(function(parent) return part:join(parent) end)
        parents:append(part)
    end

    return parents
end)

Path.parent = Path.make_fn_match_input(function(p)
    return Path.parents(p):pop(1)
end)

function Path.name(p)
    return Path.parts(p):pop()
end

function Path.suffixes(p)
    return List(Path.name(p):split(".")):transform(function(s) return "." .. s end):remove(1)
end

function Path.suffix(p)
    return PATH.extension(Path.as_string(p))
end

function Path.stem(p)
    return Path.name(p):split(".", 1)[1]
end

Path.with_name = Path.make_fn_match_input(function(p, name)
    return Path(p):parent():join(name)
end)

Path.with_stem = Path.make_fn_match_input(function(p, stem)
    return Path(p):with_name(stem .. Path.suffix(p))
end)

Path.with_suffix = Path.make_fn_match_input(function(p, suffix)
    return Path(p):with_name(Path.stem(p) .. suffix)
end)

function Path.is_relative_to(p, p2)
    p = Path.as_path(p)
    p2 = Path.as_path(p2)

    if p == p2 then
        return true
    end

    for _, parent in ipairs(p:parents()) do
        if parent == p2 then
            return true
        end
    end

    return false
end

Path.relative_to = Path.make_fn_match_input(function(p, p2)
    p2 = tostring(p2)
    if p:startswith(p2) then
        return p:removeprefix(p2):removeprefix("/")
    else
        error(tostring(p) .. " is not relative to " .. p2)
    end
end)

Path.resolve = Path.make_fn_match_input(function(p)
    p = Path.as_path(p)

    if p:parts()[1] == "." then
        p = p:removeprefix(".")
    end

    if not p:is_relative_to(Path.cwd()) then
        p = Path.cwd():join(p)
    end

    local parts = List()
    for _, part in ipairs(p:parts()) do
        if part == '..' then
            if #parts > 0 then
                parts:pop()
            end
        else
            parts:append(part)
        end
    end

    if #parts == 0 then
        parts:append(Path.root())
    end

    p = Path(parts:pop(1))
    p = p:join(unpack(parts))
    return p
end)

-- something is "file like" if it has a suffix
function Path.is_file_like(p)
    return #Path.suffix(p) > 0
end

-- something is "dir like" if it has no suffix
function Path.is_dir_like(p)
    return #Path.suffix(p) == 0
end

function Path.cwd()
    return Path(os.getenv("PWD"))
end

Path.iterdir = Path.make_list_fn_match_input(function(dir, args)
    args = Dict.from(args, {recursive = true, files = true, dirs = true})

    dir = Path.as_path(dir)

    local paths = List()
    local exclusions = Set({[[.]], [[..]]})
    for stem in lfs.dir(Path.as_string(dir)) do
        if not exclusions[stem] then
            local p = dir:join(stem)

            if (p:is_file() and args.files) or (p:is_dir() and args.dirs) then
                paths:append(p)
            end

            if p:is_dir() and args.recursive then
                paths:extend(p:iterdir(args))
            end
        end
    end

    return paths
end)

function Path.rmdir(p, force)
    p = Path.as_path(p)
    force = force or false

    if not p:exists() then
        return
    end

    if force then
        p:iterdir():reverse():foreach(function(_p)
            if _p:is_file() then
                _p:unlink()
            elseif _p:is_dir() then
                _p:rmdir()
            end
        end)
    end

    if p:is_empty() then
        PATH.rmdir(tostring(p))
    end
end

Path.root = Path(Path.sep)
Path.home = Path(os.getenv("HOME"))
Path.tempdir = Path.root:join("tmp")

return Path
