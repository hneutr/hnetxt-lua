local lyaml = require("lyaml")
local Path = require("util.path")
table = require("util.table")

local constsDir = "/Users/hne/dotfiles/lex/yaml"

function load(dir)
    local constants = {}
    for _, path in ipairs(Path.listDir(dir)) do

        local subconstants = lyaml.load(Path.read(path))

        local stem = Path.stem(path)

        if stem == "init" then
            constants = table.merge(subconstants, constants)
        else
            constants[stem] = subconstants
        end
    end

    return constants
end

print(require("inspect")(load(constsDir)))

return load(constsDir)


-- local constsPath = constsDir .. "/init.yaml"
-- local consts = lyaml.load(Path.read(constsPath))

-- print(require("inspect")(consts))

-- print(require("inspect")(Path.listDir(constsDir)))
-- local paths = 
-- for file in lfs.dir(constsDir) do
--     -- "file" is the current file or directory name
--     print( "Found file: " .. file )
-- end

