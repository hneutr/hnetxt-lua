require("hl.string")

local class = require("pl.class")
local Dict = require("hl.Dict")
local Set = require("hl.Set")
local List = require("hl.List")

class.Tree(Dict)

function Tree:_init(...)
    self:update(...)
    self:clean()
end

function Tree:get(key)
    local trees = List({self})

    while #trees > 0 do
        local tree = trees:pop()

        if tree[key] then
            return tree[key]
        end

        trees:extend(tree:values())
    end
end

function Tree:pop(key)
    local trees = List({self})

    while #trees > 0 do
        local tree = trees:pop()

        if tree[key] then
            local key_tree = tree[key]
            tree[key] = nil
            return key_tree
        end

        trees:extend(tree:values())
    end
end

function Tree:add(tree)
    Tree(tree):keys():foreach(function(key)
        local key_tree = self:get(key)

        if key_tree then
            key_tree:update(tree[key])
        else
            self[key] = Tree(tree[key])
        end
    end)
end

function Tree:add_edge(source, target)
    local source_tree
    if source then
        source_tree = self:get(source)

        if not source_tree then
            self[source] = Tree()
            source_tree = self[source]
        end
    else
        source_tree = self
    end

    if target then
        source_tree[target] = self:pop(target) or Tree()
    end

    return self
end

function Tree:parents()
    local parents = Dict()

    local trees = List({{tree = self, parent = nil}})
    while #trees > 0 do
        local t = trees:pop()
        t.tree:foreach(function(key, tree)
            parents[key] = t.parent
            trees:append({tree = tree, parent = key})
        end)
    end

    return parents
end

function Tree:ancestors()
    local ancestors = Dict():set_default(List)
    local parents = self:parents()
    parents:foreach(function(key, ancestor)
        while ancestor do
            ancestors[key]:append(ancestor)
            ancestor = parents[ancestor]
        end
    end)

    return ancestors
end

function Tree:generations()
    local ancestors = self:ancestors()
    local generations = Dict():set_default(0)
    self:nodes():foreach(function(key) generations[key] = #ancestors[key] + 1 end)
    return generations
end

function Tree:descendants()
    local descendants = Dict():set_default(List)
    local parents = self:parents()
    parents:foreach(function(key, parent)
        while parent do
            descendants[parent]:append(key)
            parent = parents[parent]
        end
    end)

    return descendants
end

function Tree:children()
    local children = Dict():set_default(List)
    local parents = self:parents()
    parents:foreach(function(key, parent)
        children[parent]:append(key)
    end)

    children:values():foreach(function(l) l:sort() end)
    return children
end

function Tree:nodes()
    local nodes = Set()
    local trees = List({self})
    while #trees > 0 do
        local tree = trees:pop()
        nodes:add(tree:keys())
        trees:extend(tree:values())
    end

    return nodes:vals()
end

function Tree:clean()
    self:transformv(function(v)
        if type(v) ~= 'function' then
            if v.is_a == nil or not v:is_a(Tree) then
                v = Tree(v)
            end
        end

        return v
    end)
end

return Tree
