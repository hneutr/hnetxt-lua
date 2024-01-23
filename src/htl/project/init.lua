local Yaml = require("hl.yaml")
local Path = require("hl.Path")
local List = require("hl.List")
local Dict = require("hl.Dict")

local class = require("pl.class")

local Config = require("htl.config")
local Registry = require("htl.project.registry")

class.Project()
Project.config = Config.get("project")

function Project:_init(name)
    self.name = name
    self.root = Registry.get_entry_dir(self.name)

    self.metadata = Yaml.read(self.get_metadata_path(self.root))
end

function Project.get_metadata_path(dir)
    dir = Path(dir or Path.cwd())
    return dir:join(Project.config.metadata_filename)
end

function Project.create(name, dir, metadata)
    metadata = Dict.from(metadata, {date = os.date("%Y%m%d")})
    metadata.date = tonumber(metadata.date)

    if not name or not dir then
        return
    end

    metadata.name = name:gsub("%-", " ")

    Yaml.write(Project.get_metadata_path(dir), metadata)
    Registry.set_entry(name, dir)
end

function Project.root_from_path(path)
    path = Path(path or Path.cwd())
    local name = Registry.get_entry_name(path)
    return Registry.get_entry_dir(name)
end

return Project
