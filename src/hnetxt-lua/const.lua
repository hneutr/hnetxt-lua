local lyaml = require("lyaml")
local Path = require("hneutil.path")
table = require("hneutil.table")

local constsDir = "/Users/hne/dotfiles/lex/yaml"

function load(dir)
    local constants = {}
    for _, path in ipairs(Path.iterdir(dir)) do
        local subconstants = lyaml.load(Path.read(path))

        local stem = Path.stem(path)

        if stem == "init" then
            constants = table.default(subconstants, constants)
        else
            constants[stem] = subconstants
        end
    end

    return constants
end

return load(constsDir)
