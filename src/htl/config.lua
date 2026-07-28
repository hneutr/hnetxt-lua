require("hl")

local Yaml = require("hl.yaml")

local M = {}

M.constants_dir = Path.home / "lib/hnetxt-lua/constants"
M.root = Path.home

--------------------------------------------------------------------------------
--                                    Paths                                   --
--------------------------------------------------------------------------------
M.Paths = {}

function M.Paths.define(key, path, parent)
    path = parent and parent / path or Path(path)

    if path:is_relative_to(Path.tempdir) then
        if key:endswith("_file") then
            path:touch()
        elseif key:endswith("_dir") then
            path:mkdir()
        end
    end

    return path
end

function M.Paths.get_object(constants)
    constants = Dict(constants)
    local d = {root = M.root, tempdir = Path.tempdir}

    return setmetatable(
        {keys = function() return constants:keys() end},
        {
            __tostring = function() return tostring(d) end,
            __index = function(self, key)
                local c = constants[key]
                if not d[key] and c then
                    d[key] = M.Paths.define(
                        key,
                        c.path,
                        c.parent and self[c.parent]
                    )
                end

                return d[key]
            end,
        }
    )
end

--------------------------------------------------------------------------------
--                                   Mirrors                                  --
--------------------------------------------------------------------------------
M.Mirrors = {}

function M.Mirrors.get_object(constants)
    constants = Dict(constants)
    local d = {}

    return setmetatable(
        {keys = function() return constants:keys() end},
        {
            __index = function(self, key)
                local conf = constants[key]
                if not d[key] and conf then
                    conf.path = Conf.paths.mirrors_dir / key
                    conf.statusline_str = conf.statusline_str or key
                    d[key] = conf
                end

                return d[key]
            end,
        }
    )
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 Constants                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.Constants = {}

function M.Constants.define(key, path)
    if path:is_dir() then
        return M.Constants.get_object(path)
    end

    local val = Yaml.read(path)

    if key == 'paths' then
        val = M.Paths.get_object(val)
    elseif key == 'mirror' then
        val = M.Mirrors.get_object(val)
    end

    return val
end

function M.Constants.get_object(dir)
    local d = {}

    local key_to_path = Dict.from_list(
        dir:iterdir({recursive = false}),
        function(p) return p:relative_to(dir):stem(), p end
    )

    return setmetatable(
        {keys = function() return key_to_path:keys() end},
        {
            __index = function(_, key)
                if not d[key] and key_to_path[key] then
                    d[key] = M.Constants.define(key, key_to_path[key])
                end

                return d[key]
            end,
        }
    )
end

function M.init()
    Conf = M.Constants.get_object(M.constants_dir)
end

M.init()

return M
