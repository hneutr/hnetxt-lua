local List = require("hl.PList")
local Path = require("hl.path")
local Object = require("hl.object")

local Project = require("htl.project")
local Config = require("htl.project.mirror.config")

local Mirror = Object:extend()
Mirror.type_configs = Config.load()

function Mirror:new(path, type_name)
    if not type_name then
        type_name = Mirror.path_type(path)
    end

    self.type_name = type_name

    self = Dict.update(self, self.type_configs[type_name])

    self.root = Project.root_from_path(path)

    self.dir = Path.joinpath(self.root, self.dir)

    if Path.is_relative_to(path, self.dir) then
        self.path = path
        self.relative_path = Path.relative_to(path, self.dir)
    else
        self.path = Path.joinpath(self.dir, path)
        self.relative_path = path
    end

    self.project_path = Path.relative_to(self.path, self.root)
    self.project_dir = Path.relative_to(self.dir, self.root)

    self.unmirrored_path = Path.joinpath(self.root, self.relative_path)
end

function Mirror:get_mirror_path(type_name)
    return Path.joinpath(self.root, self.type_configs[type_name].dir, self.project_path)
end

function Mirror:get_mirror_paths(existing_only)
    if existing_only == nil then
        existing_only = true
    end

    local paths = {}
    for _, type_name in ipairs(self.mirror_types) do
        local path = self:get_mirror_path(type_name)

        if existing_only and not Path.exists(path) then
            path = nil
        end

        paths[#paths + 1] = path
    end

    return paths
end

function Mirror.get_all_mirrored_paths(path, existing_only)
    if existing_only == nil then
        existing_only = true
    end

    local paths = List()
    local to_check = List({path})
    while #to_check > 0 do
        local path = to_check:pop()
        to_check:extend(Mirror(path):get_mirror_paths(existing_only))
        paths:append(path)
    end

    return paths
end

function Mirror.path_type(path)
    local root = Project.root_from_path(path)
    local project_path = Path.relative_to(path, root)

    for type_name, type_config in pairs(Mirror.type_configs) do
        if Path.is_relative_to(project_path, type_config.dir) then
            return type_name
        end
    end

    return "source"
end

function Mirror.find_updates(old_path, new_path, existing_only)
    if existing_only == nil then
        existing_only = true
    end

    local updates = {}
    local to_check = {[old_path] = new_path}
    while #Dict.keys(to_check) > 0 do
        local old_path, new_path = next(to_check)
        to_check[old_path] = nil

        if not existing_only or Path.exists(old_path) then
            updates[old_path] = new_path

            local old = Mirror(old_path)
            local new = Mirror(new_path)

            assert(old.type_name == new.type_name)

            for _, type_name in ipairs(old.mirror_types) do
                to_check[old:get_mirror_path(type_name)] = new:get_mirror_path(type_name)
            end
        end
    end

    return updates
end

return Mirror
