local lyaml = require("lyaml")

local Dict = require("hl.Dict")
local Tree = require("hl.Tree")
local List = require("hl.List")

local Config = require("htl.Config")

return function(path)
    local paths = List()
    if path then
        paths = path:parents()

        if path:is_dir() then
            paths:append(path)
        end

        paths = paths:transform(function(p)
            return p:join(Config.get("taxonomy").file_name)
        end):filter(function(p)
            return p:exists()
        end)
    end

    paths:put(Config.paths.global_taxonomy_file)

    local tree = Tree()

    paths:foreach(function(path)
        tree:add(Tree(lyaml.load(path:read())))
    end)

    return tree
end
