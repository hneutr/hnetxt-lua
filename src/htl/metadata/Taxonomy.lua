local lyaml = require("lyaml")

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
            return p:join(Conf.paths.taxonomy_file)
        end):filter(function(p)
            return p:exists()
        end)
    end

    paths:put(Conf.paths.global_taxonomy_file)

    local tree = Tree()

    paths:foreach(function(path)
        tree:add(Tree(lyaml.load(path:read())))
    end)

    return tree
end
