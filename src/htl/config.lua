local Yaml = require("hl.yaml")

local M = {}
M.constants_dir = Path.home / "lib/hnetxt-lua/constants"
M.test_root = Path.tempdir / "test-root"

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
    })
end

local function get_constants_object(args)
    args = args or {}
    args.dir = args.dir or M.constants_dir
    
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

function M.before_test()
    Conf = get_constants_object({for_test = true})
end

function M.after_test()
    M.test_root:rmdir(true)
end

Conf = get_constants_object()

return M
