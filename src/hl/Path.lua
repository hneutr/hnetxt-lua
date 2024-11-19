--[[
unimplemented implement:
- pathlib (python):
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

require("hl.string")

class.Path()

local M = Path

M.sep = "/"

function M.as_string(p)
    if p ~= nil and type(p) ~= 'string' then
        p = tostring(p)
    end

    return p
end

List({
    "startswith",
    "endswith",
    "split",
}):foreach(function(fn)
    M[fn] = function(p, ...)
        return string[fn](M.as_string(p), ...)
    end
end)

List({
    "removesuffix",
    "removeprefix",
}):foreach(function(fn)
    M[fn] = function(p, ...)
        return M(string[fn](p.p, ...))
    end
end)


function M:_init(path)
    self.p = M.expanduser(M.as_string(path))
end

function M:__concat(p) return self:join(p) end

function M:__tostring() return self.p end

function M.__eq(p1, p2) return tostring(p1) == tostring(p2) end
function M.__lt(p1, p2) return tostring(p1) < tostring(p2) end
function M.__gt(p1, p2) return tostring(p1) > tostring(p2) end

function M.is_file(p) return PATH.isfile(M.as_string(p)) and true end

function M.is_dir(p) return PATH.isdir(M.as_string(p)) and true end

function M.is_url(p) return M.as_string(p):startswith("http") and true end

function M.exists(p) return PATH.exists(M.as_string(p)) and true end

function M.is_empty(p) return PATH.isempty(M.as_string(p)) and true end

function M.mkdir(p) PATH.mkdir(M.as_string(p)) end

function M.unlink(p) PATH.remove(M.as_string(p)) end

function M:parts()
    local parts = List(self.p:split(M.sep)):filter(function(part)
        return #part > 0
    end)

    if self.p:startswith(M.sep) then
        parts:put(M.sep)
    end

    return parts
end

function M:read()
    local fh = io.open(tostring(self), "r")
    local content = fh:read("*a")
    fh:close()
    return content
end

function M:readlines() return List(self:read():splitlines()) end

function M:write(content)
    if not self:parent():exists() then
        self:parent():mkdir()
    end

    local fh = io.open(tostring(self), "w")
    fh:write(List.as_list(content):map(tostring):join("\n"))
    fh:close()
end

function M:touch() return not self:exists() and self:write("") end

function M.expanduser(p) return tostring(p):gsub("~", tostring(M.home)) end

function M.contractuser(p)
    local s = tostring(p):gsub(tostring(M.home), "~")

    if M.is_a(p) == M then
        p.p = s
    else
        p = s
    end

    return p
end

function M:rename(target)
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

function M:join(...)
    local parts = List(...)
    if type(...) == "string" or M.is_a(...) == M then
        parts = List({...})
    end

    parts:transform(function(part)
        return string.removeprefix(tostring(part) or "", M.sep)
    end)

    parts = parts:filter(function(part)
        return part and #part > 0
    end)

    parts:put(self.p:removesuffix(M.sep))

    return M(parts:join(M.sep))
end

M.__div = M.join

function M:parents()
    local parts = self:parts()
    parts:pop()

    local parents = List()
    for _, part in ipairs(parts:reverse()) do
        part = M(part)
        parents:transform(function(parent) return part:join(parent) end)
        parents:append(part)
    end

    return parents
end

function M.parent(p)
    local s = tostring(p)

    local parent = ""
    if s:match("/") then
        parent = s:rsplit(M.sep, 1)[1]
        parent = #parent > 0 and parent or s:startswith(M.sep) and M.sep
    end

    return M(parent)
end

function M.name(p)
    local parts = tostring(p):rsplit(M.sep, 1)
    return parts[#parts]
end

function M.suffixes(p)
    return List(M.name(p):split(".")):transform(function(s) return "." .. s end):remove(1)
end

function M.suffix(p) return PATH.extension(tostring(p)) end

function M.stem(p) return M.name(p):split(".", 1)[1] end

function M.with_name(p, name)
    if tostring(p):match(M.sep) then
        return M.parent(p):join(name)
    end

    return M(name)
end

function M.with_stem(p, stem)
    local name = M.name(p):gsub(M.stem(p), stem, 1)
    return M.with_name(p, name)
end

function M.with_suffix(p, suffix)
    return M.with_name(p, M.stem(p) .. suffix)
end

function M.is_absolute(p) return tostring(p):startswith(M.sep) end

function M.is_relative_to(p, other) return tostring(p):startswith(tostring(other)) end

function M.relative_to(p, other)
    local a = tostring(p)
    local b = tostring(other)
    if a:startswith(b) then
        return M(a:removeprefix(b):removeprefix("/"))
    else
        error(a .. " is not relative to " .. b)
    end
end

function M:resolve()
    self.p = self.p:removeprefix("./")

    if not self:is_relative_to(M.root) and not self:is_relative_to(M.cwd()) then
        self = M.cwd():join(self)
    end

    local parts = List()
    for part in self:parts():iter() do
        if part == '..' then
            if #parts > 0 then
                parts:pop()
            end
        elseif part ~= '.' then
            parts:append(part)
        end
    end

    if #parts == 0 then
        parts:append(M.root)
    end

    return M(""):join(unpack(parts))
end

function M:iterdir(args)
    args = Dict(args, {recursive = true, files = true, dirs = true, hidden=false})

    local paths = List()
    local exclusions = List({[[.]], [[..]]})
    for stem in lfs.dir(tostring(self)) do
        if not exclusions:contains(stem) then
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

function M:files(args)
    args = args or {}
    args.files = true
    args.dirs = false

    return self:iterdir(args)
end

function M:glob(pattern, args)
    return M.iterdir(self, args):filter(function(p)
        return tostring(p):match(pattern)
    end)
end

function M:rmdir(force)
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

function M:open(open_command)
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

function M.string_to_path(s)
    s = s:gsub("%-", "_")
    s = s:gsub("%s", "-")
    return M(s)
end

function M.from_cli(path) return M(path):resolve() end

function M.this() return M(vim.fn.expand('%:p')) end

function M.cwd() return M(os.getenv("PWD")) end

M.root = M(M.sep)
M.home = M(os.getenv("HOME"))
M.tempdir = M.root:join("tmp")

return M
