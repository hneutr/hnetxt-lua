local Path = require("hl.path")
local List = require("hl.List")
local Dict = require("hl.Dict")

local class = require("pl.class")

local db = require("htl.db")
local Config = require("htl.config")

class.Mirror()

function Mirror.load(config)
    config = config or Config.get("mirror")

    local category_mirrors = Dict(config.category_mirrors):transformv(List)
    local mirrors = Dict(config.mirrors):transformv(Dict)

    local mirrors_by_category = Dict()
    mirrors:foreach(function(name, mirror)
        mirror.mirrors = List()
        mirror.dir = Path.join("." .. mirror.category, name)
        
        mirrors_by_category:default(mirror.category, List()):append(name)
    end)

    mirrors:foreach(function(name, mirror)
        mirror.to_mirror = List()
        category_mirrors[mirror.category]:foreach(function(category)
            mirrors_by_category[category]:foreach(function(other)
                mirror.to_mirror:append(other)
                mirrors[other].mirrors:append(name)
            end)
        end)
    end)

    mirrors.source.dir = ""

    return mirrors
end

Mirror.configs = Mirror.load()

function Mirror:_init(path)
    self.path = path
    self.mirror_name = Mirror.path_type(self.path)

    self = Dict.update(self, self.configs[self.mirror_name])

    self.root = db.get()['projects'].get_path(self.path)
    self.dir = Path.join(self.root, self.dir)

    if not Path.is_relative_to(self.path, self.dir) then
        self.path = Path.join(self.dir, self.path)
    end
end

function Mirror:get_mirror_path(mirror)
    return Path.join(
        self.root,
        self.configs[mirror].dir,
        Path.relative_to(self.path, self.root)
    )
end

function Mirror:get_mirror_paths()
    return self.mirrors:map(function(m)
        return self:get_mirror_path(m)
    end):filter(function(path)
        return Path.exists(path)
    end)
end

function Mirror.get_all_mirrored_paths(path)
    local paths = List()
    local to_check = List({path})
    while #to_check > 0 do
        local path = to_check:pop()
        to_check:extend(Mirror(path):get_mirror_paths())
        paths:append(path)
    end

    return paths
end

function Mirror.path_type(path)
    local root = db.get()['projects'].get_path(path)

    local project_path = path

    if Path.is_relative_to(project_path, root) then
        project_path = Path.relative_to(path, root)
    end

    for name, type_config in pairs(Mirror.configs) do
        if Path.is_relative_to(project_path, type_config.dir) then
            return name
        end
    end

    return "source"
end

function Mirror.find_updates(old_path, new_path)
    local updates = {}
    local to_check = {[old_path] = new_path}
    while #Dict.keys(to_check) > 0 do
        local old_path, new_path = next(to_check)
        to_check[old_path] = nil

        if Path.exists(old_path) then
            updates[old_path] = new_path

            local old = Mirror(old_path)
            local new = Mirror(new_path)

            assert(old.mirror_name == new.mirror_name)

            old.mirrors:foreach(function(mirror)
                to_check[old:get_mirror_path(mirror)] = new:get_mirror_path(mirror)
            end)
        end
    end

    return updates
end

return Mirror
