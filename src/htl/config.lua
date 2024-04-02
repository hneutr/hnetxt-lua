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

function M.get_path(key, configs)
    if not M.paths[key] then
        local conf = configs[key]
        local path = conf.path

        if conf.parent then
            path = M.get_path(configs[key].parent, configs):join(path)
        end

        M.paths[key] = Path(path)
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

    local paths = M.get("paths")

    M.paths:foreach(function(k, v)
        if paths[k] and v:is_absolute() then
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

local function get_paths_object(constants, for_test)
    local root = for_test and M.test_root or Path.home
    local d = Dict({root = root})

    local function setup_path(key, path)
        if for_test and path:is_absolute() then
            if key:endswith("_file") then
                path:touch()
            elseif key:endswith("_dir") then
                path:mkdir()
            end
        end
    end

    return setmetatable({}, {
        __index = function(self, key)
            if not d[key] then
                local path = constants[key].path
                local parent = constants[key].parent

                if parent then
                    path = self[parent] / path
                end

                d[key] = Path(path)
            end

            setup_path(key, d[key])

            return d[key]
        end,

        __newindex = function(self, ...) rawset(d, ...) end,
        __tostring = function() return tostring(d) end,
        keys = function(self) return constants:keys() end,
    })
end

local function get_constants_object(args)
    args = args or {}
    args.dir = args.dir or M.constants_dir
    
    local dir = args.dir
    local d = Dict({})

    local stem_to_path = Dict.from_list(
        args.dir:iterdir({recursive = false}),
        function(p) return p:relative_to(args.dir):stem(), p end
    )

    local methods = {
        keys = function()
            return stem_to_path:keys()
        end,
    }

    return setmetatable(methods, {
        __index = function(self, key)
            
            if not d[key] then
                local path = stem_to_path[key]
                if path then
                    if path:is_dir() then
                        d[key] = get_constants_object({dir = path, for_test = args.for_test})
                    else
                        d[key] = Yaml.read(path)

                        if key == 'paths' then
                            d[key] = get_paths_object(d[key], args.for_test)
                        end
                    end
                end
            end

            return d[key]
        end,
        __newindex = function(self, ...) rawset(d, ...) end,
        __tostring = function() return tostring(d) end,
    })
end

Conf = get_constants_object()

function M.Nbefore_test()
    Conf = get_constants_object({for_test = true})
end

function M.Nafter_test()
    M.test_root:rmdir(true)
end

return M
