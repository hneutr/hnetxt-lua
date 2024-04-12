require("hl")

local Yaml = require("hl.yaml")

local M = {}

M.constants_dir = Path.home / "lib/hnetxt-lua/constants"
M.test_root = Path.tempdir / "test-root"
M.root = Path.home

M.Paths = {}

function M.Paths.define(key, for_test, path, parent)
    if parent then
        path = parent / path
    else
        path = Path(path)
    end

    if for_test and path:is_absolute() then
        if key:endswith("_file") then
            path:touch()
        elseif key:endswith("_dir") then
            path:mkdir()
        end
    end

    return path
end

function M.Paths.get_object(constants)
    local d = Dict({root = M.root})
    local for_test = M.root == M.test_root

    return setmetatable({}, {
        __newindex = function(self, ...) rawset(d, ...) end,
        __tostring = function() return tostring(d) end,
        __index = function(self, key)
            local conf = constants[key]
            if not d[key] and conf then
                d[key] = M.Paths.define(
                    key,
                    for_test,
                    conf.path,
                    conf.parent and self[conf.parent]
                )
            end

            return d[key]
        end,
    })
end

M.DBTable = {}
M.DBTable.remaps = Dict({
    TODAY = [[strftime('%Y%m%d')]],
})

function M.DBTable.parse(raw)
    local d = {}
    Dict(raw):foreach(function(col, conf)
        d[col] = conf
        if type(conf) == 'table' then
            for key, val in pairs(conf) do
                if M.DBTable.remaps[val] ~= nil then
                    val = M.DBTable.remaps[val]
                end
                d[col][key] = val
            end
        end
    end)
    return d
end

M.Constants = {}

function M.Constants.define(key, path)
    if path:is_dir() then
        return M.Constants.get_object(path)
    end

    local val = Yaml.read(path)

    if key == 'paths' then
        val = M.Paths.get_object(val)
    elseif path:parent():stem() == "db" then
        val = M.DBTable.parse(val)
    end

    return val
end

function M.Constants.get_object(dir)
    dir = dir or M.constants_dir
    
    local d = Dict({})

    local stem_to_path = Dict.from_list(
        dir:iterdir({recursive = false}),
        function(p) return p:relative_to(dir):stem(), p end
    )

    return setmetatable(
        {
            keys = function() return stem_to_path:keys() end,
        },
        {
            __newindex = function(self, ...) rawset(d, ...) end,
            __tostring = function() return tostring(d) end,
            __index = function(self, key)
                if not d[key] and stem_to_path[key] then
                    d[key] = M.Constants.define(key, stem_to_path[key])
                end

                return d[key]
            end,
        }
    )
end

function M.before_test()
    M.root = M.test_root
    M.init()
end

function M.after_test()
    M.test_root:rmdir(true)
    M.root = Path.home
end

function M.init()
    Conf = M.Constants.get_object()
end

M.init()

return M
