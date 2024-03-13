local Yaml = require("hl.yaml")
local Dict = require("hl.Dict")
local Path = require("hl.Path")
local List = require("hl.List")

local M = {}
M.constants_dir = Path.home:join("lib/hnetxt-lua/constants")
M.constants_suffix = ".yaml"
M.root = Path.home
M.test_root = Path.tempdir:join("test-root")

function M.get(constants_type)
    local path = M.constants_dir:join(constants_type):with_suffix(M.constants_suffix)
    return Yaml.read(path)
end

function M.get_dir(constants_type)
    local d = Dict()
    M.constants_dir:join(constants_type):glob("%.yaml$"):foreach(function(p)
        d[p:stem()] = Yaml.read(p)
    end)
    return d
end

function M.setup_paths(configs)
end

function M.get_path(key, configs)
    if not M.paths[key] then
        local conf = configs[key]
        local path = conf.path

        if conf.parent then
            path = M.get_path(configs[key].parent, configs):join(path)
        end

        M.paths[key] = path
    end

    return M.paths[key]
end

function M.setup()
    M.paths = Dict({root = M.root})

    local path_configs = Dict(M.get("paths"))
    path_configs:keys():foreach(function(key)
        M.get_path(key, path_configs)
    end)
end

function M.before_test()
    M.root = M.test_root
    M.setup()

    local conf = M.get("paths")

    M.paths:foreach(function(k, v)
        if conf[k] and not conf[k].is_relative then
            if k:endswith("_file") then
                v:touch()
            elseif k:endswith("_dir") then
                v:mkdir()
            end
        end
    end)
end

function M.after_test()
    M.test_root:rmdir(true)
    M.root = Path.home
    M.setup()
end

M.setup()

return M
