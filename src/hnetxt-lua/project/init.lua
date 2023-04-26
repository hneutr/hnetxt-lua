local yaml = require("hneutil.yaml")
local Object = require("hneutil.object")
local Path = require("hneutil.path")

table = require("hneutil.table")
string = require("hneutil.string")

local Config = require("hnetxt-lua.config")
local Registry = require("hnetxt-lua.project.registry")

local Project = Object:extend()
Project.config = Config.get("project")

function Project:new(name)
    self.name = name
    self.registry = Registry()
    self.root = self.registry:get_entry_dir(self.name)

    self.metadata = yaml.read(self.get_metadata_path(self.root))
    self.journal_dir = Path.joinpath(self.root, self.config.journal_dir)
end

function Project.get_metadata_path(dir)
    dir = dir or Path.cwd()
    return Path.joinpath(dir, Project.config.metadata_filename)
end

function Project.create(name, dir, metadata)
    metadata = table.default(metadata, {start_date = os.date("%Y%m%d")})

    if not name or not dir then
        return
    end

    metadata.name = name

    yaml.write(Project.get_metadata_path(dir), metadata)
    Registry():set_entry(name, dir)
end

function Project.in_project(path)
    path = path or Path.cwd()

    if not Path.is_dir(path) then
        path = Path.parent(path)
    end

    local candidates = table.list_extend({path}, Path.parents(path))

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

function Project:get_journal_path(args)
    args = table.default(args, {
        year = os.date("%Y"),
        month = os.date("%m"),
    })
    
    local filename = args.year .. args.month .. ".md"

    return Path.joinpath(self.journal_dir, filename)
end

return Project
