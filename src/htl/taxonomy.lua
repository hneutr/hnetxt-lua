local class = require("pl.class")
local lyaml = require("lyaml")

local Dict = require("hl.Dict")
local List = require("hl.List")

local Config = require("htl.Config")

class.Taxonomy()
Taxonomy.file_name = Config.get("taxonomy").file_name

function Taxonomy:_init(path)
    self.tree = self:set_tree(path)
    self.children = self:set_children(self.tree)
    self.parents = self:set_parents(self.tree)
end

function Taxonomy:set_tree(path)
    local paths = List()
    if path then
        paths = path:parents()

        if path:is_dir() then
            paths:append(path)
        end

        paths = paths:transform(function(p)
            return p:join(self.file_name)
        end):filter(function(p)
            return p:exists()
        end)
    end

    paths:put(Config.paths.global_taxonomy_file)

    local tree = Dict()

    paths:foreach(function(path)
        tree:update(lyaml.load(path:read()))
    end)

    return tree
end

function Taxonomy:set_children(tree, parents, children)
    if parents == nil then
        parents = List()
    end

    if children == nil then
        children = Dict()
    end

    Dict(tree):foreach(function(key, subtree)
        children[key] = List()

        parents:foreach(function(p)
            children[p]:append(key)
        end)

        if subtree then
            self:set_children(subtree, parents:clone():append(key), children)
        end
    end)

    children:foreachv(function(v)
        v:sort()
    end)

    return children
end

function Taxonomy:set_parents(tree, parents, parent)
    if parents == nil then
        parents = Dict()
    end

    Dict(tree):foreach(function(child, subtree)
        parents[child] = parent

        if subtree then
            self:set_parents(subtree, parents, child)
        end
    end)

    return parents
end

function Taxonomy:get_precedence(key)
    local precedence = 0

    while key do
        key = self.parents[key]
        precedence = precedence + 1
    end

    return precedence
end

return Taxonomy
