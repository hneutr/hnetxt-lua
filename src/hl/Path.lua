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

require("hl.string")

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

List({
    "startswith",
    "endswith",
    "split",
}):foreach(function(fn)
    Path[fn] = function(p, ...)
        return string[fn](Path.as_string(p), ...)
    end
end)

List({
    "removesuffix",
    "removeprefix",
}):foreach(function(fn)
    Path[fn] = function(p, ...)
        return Path(string[fn](p.p, ...))
    end
end)


function Path:_init(path)
    self.p = Path.expanduser(Path.as_string(path))
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

function Path.is_url(p)
    return Path.as_string(p):startswith("http") and true
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

function Path:parts()
    local parts = List(self.p:split(self.sep)):filter(function(part)
        return #part > 0
    end)

    if self.p:startswith(self.sep) then
        parts:put(self.sep)
    end

    return parts
end

function Path:read()
    local fh = io.open(tostring(self), "r")
    local content = fh:read("*a")
    fh:close()
    return content
end

function Path:readlines()
    return List(self:read():splitlines())
end

function Path:write(content)
    if not self:parent():exists() then
        self:parent():mkdir()
    end

    content = List.as_list(content)
    content:transform(tostring)

    local fh = io.open(tostring(self), "w")
    fh:write(content:join("\n"))
    fh:close()
end

function Path:touch()
    if not self:exists() then
        self:write("")
    end
end

function Path.expanduser(p)
    return string.gsub(tostring(p), "~", tostring(Path.home))
end

function Path.contractuser(p)
    local s = string.gsub(tostring(p), tostring(Path.home), "~")

    if Path.is_a(p) == Path then
        p.p = s
    else
        p = s
    end

    return p
end

function Path:rename(target)
    local source = tostring(self)
    target = tostring(target)

    if self:is_file() then
        PATH.rename(source, target, true)
    elseif self:is_dir() then
        os.rename(source, target)

        if source ~= target then
            self:rmdir(true)
        end
    end
end

function Path:join(...)
    local parts = List(...)
    if type(...) == "string" or Path.is_a(...) == Path then
        parts = List({...})
    end

    parts:transform(function(part)
        return string.removeprefix(tostring(part) or "", self.sep)
    end)

    parts = parts:filter(function(part)
        return part and #part > 0
    end)

    parts:put(self.p:removesuffix(self.sep))

    return Path(parts:join(self.sep))
end


Path.__div = function(...)
    return Path.join(...)
end

function Path:parents()
    local parts = self:parts()
    parts:pop()

    local parents = List()
    for _, part in ipairs(parts:reverse()) do
        part = Path(part)
        parents:transform(function(parent) return part:join(parent) end)
        parents:append(part)
    end

    return parents
end

function Path:parent()
    return self:parents():pop(1)
end

function Path:name()
    return self:parts():pop()
end

function Path:suffixes()
    return List(self:name():split(".")):transform(function(s) return "." .. s end):remove(1)
end

function Path:suffix()
    return PATH.extension(tostring(self))
end

function Path:stem()
    return self:name():split(".", 1)[1]
end

function Path:with_name(name)
    if #self:parents() > 0 then
        return self:parent():join(name)
    end

    return Path(name)
end

function Path:with_stem(stem)
    return self:with_name(stem .. self:suffix())
end

function Path:with_suffix(suffix)
    return self:with_name(self:stem() .. suffix)
end

function Path:is_absolute()
    return string.startswith(tostring(self), self.sep)
end

function Path:is_relative_to(other)
    return string.startswith(tostring(self), tostring(other))
end

function Path:relative_to(other)
    local a = tostring(self)
    local b = tostring(other)
    if a:startswith(b) then
        return Path(a:removeprefix(b):removeprefix("/"))
    else
        error(a .. " is not relative to " .. b)
    end
end

function Path:resolve()
    self.p = self.p:removeprefix("./")

    if not self:is_relative_to(self.root) and not self:is_relative_to(self.cwd()) then
        self = self.cwd():join(self)
    end

    local parts = List()
    for part in self:parts():iter() do
        if part == '..' then
            if #parts > 0 then
                parts:pop()
            end
        else
            parts:append(part)
        end
    end

    if #parts == 0 then
        parts:append(self.root)
    end

    return Path(""):join(unpack(parts))
end

function Path:iterdir(args)
    args = Dict(args, {recursive = true, files = true, dirs = true, hidden=false})

    local paths = List()
    local exclusions = Set({[[.]], [[..]]})
    for stem in lfs.dir(tostring(self)) do
        if not exclusions[stem] then
            local p = self:join(stem)

            if (p:is_file() and args.files) or (p:is_dir() and args.dirs) then
                paths:append(p)
            end

            if p:is_dir() and args.recursive then
                paths:extend(p:iterdir(args))
            end
        end
    end

    if not args.hidden then
        paths = paths:filter(function(path)
            return not tostring(path:relative_to(self)):startswith('.')
        end)
    end

    return paths
end

function Path:glob(pattern, args)
    return Path.iterdir(self, args):filter(function(p)
        return tostring(p):match(pattern)
    end)
end

function Path:rmdir(force)
    force = force or false

    if not self:exists() then
        return
    end

    if force then
        self:iterdir({hidden=true}):reverse():foreach(function(_p)
            if _p:is_file() then
                _p:unlink()
            elseif _p:is_dir() then
                _p:rmdir()
            end
        end)
    end

    if self:is_empty() then
        PATH.rmdir(tostring(self))
    end
end

function Path:open(open_command)
    open_command = open_command or "edit"

    if #self:suffix() > 0 then
        self:parent():mkdir()
    else
        self:mkdir()
    end

    if self:is_dir() then
        -- if it's a directory, open a terminal at that directory
        vim.cmd("silent " .. open_command)
        vim.cmd("silent terminal")

        local term_id = vim.b.terminal_job_id

        vim.cmd("silent call chansend(" .. term_id .. ", 'cd " .. tostring(self) .. "\r')")
        vim.cmd("silent call chansend(" .. term_id .. ", 'clear\r')")
    else
        self:touch()
        vim.cmd("silent " .. open_command .. " " .. tostring(self))
    end
end

function Path.from_commandline(path)
    return Path(path):resolve()
end

function Path.this()
    return Path(vim.fn.expand('%:p'))
end

function Path.cwd()
    return Path(os.getenv("PWD"))
end

Path.root = Path(Path.sep)
Path.home = Path(os.getenv("HOME"))
Path.tempdir = Path.root:join("tmp")

return Path
