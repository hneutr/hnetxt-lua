local Yaml = require("hl.yaml")
local Path = require("hl.Path")
local Dict = require("hl.Dict")
local List = require("hl.List")

local Config = require("htl.config")

local M = {}

M.path = Config.data_dir:join("projects", Config.get("project").registry_filename)

function M.get()
    local registry = {}
    if M.path:exists() then
        registry = Yaml.read(M.path)
    end
    return Dict(registry)
end

function M.set(registry)
    registry = Dict.from(registry or {})
    local _registry = Dict()
    for _, k in ipairs(List(registry:keys()):sorted()) do
        _registry[k] = registry[k]
    end

    Yaml.write(M.path, _registry)
end

function M.set_entry(name, path)
    local registry = M.get()
    if path ~= nil then
        path = tostring(path)
    end
    registry[name] = path
    M.set(registry)
end

function M.get_entry_dir(name)
    return Path.as_path(M.get()[name])
end

function M.remove_entry(name)
    M.set_entry(name, nil)
end

function M.get_entry_name(dir)
    for name, path in pairs(M.get()) do
        if dir == path or Path.is_relative_to(dir, path) then
            return name
        end
    end

    return nil
end

return M
