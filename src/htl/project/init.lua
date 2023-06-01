local Yaml = require("hl.yaml")
local Object = require("hl.object")
local Path = require("hl.path")
local List = require("hl.List")
local Dict = require("hl.Dict")

local Config = require("htl.config")
local Registry = require("htl.project.registry")

local Project = Object:extend()
Project.config = Config.get("project")

function Project:new(name)
    self.name = name
    self.registry = Registry()
    self.root = self.registry:get_entry_dir(self.name)

    self.metadata = Yaml.read(self.get_metadata_path(self.root))
end

function Project.get_metadata_path(dir)
    dir = dir or Path.cwd()
    return Path.joinpath(dir, Project.config.metadata_filename)
end

function Project.create(name, dir, metadata)
    metadata = Dict.from(metadata, {date = os.date("%Y%m%d")})
    metadata.date = tonumber(metadata.date)

    if not name or not dir then
        return
    end

    metadata.name = name

    Yaml.write(Project.get_metadata_path(dir), metadata)
    Registry():set_entry(name, dir)
end

function Project.in_project(path)
    path = path or Path.cwd()

    if not Path.is_dir(path) then
        path = Path.parent(path)
    end

    local candidates = List.from({path}, Path.parents(path))

    for _, candidate in ipairs(candidates) do
        if Path.exists(Project.get_metadata_path(candidate)) then
            return true
        end
    end

    return false
end

function Project.from_path(path)
    path = path or Path.cwd()
    local name = Registry():get_entry_name(path)

    if name then
        return Project(name)
    end

    return nil
end

function Project.root_from_path(path)
    path = path or Path.cwd()
    local registry = Registry()
    local name = registry:get_entry_name(path)
    return registry:get_entry_dir(name)
end

return Project
