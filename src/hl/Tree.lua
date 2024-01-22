string = require("hl.string")

local class = require("pl.class")
local Dict = require("hl.Dict")
local List = require("hl.List")

class.Tree(Dict)

function Tree:_init(...)
    self:update(...)
    self:clean()
end

function Tree:set(keys)
    keys = List(keys):reverse()

    local t = self
    while #keys > 0 do
        local key = keys:pop()

        if not t[key] then
            t[key] = Tree()
        end

        t = t[key]
    end

    return self
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

function Tree:transform(...)
    self:transformk(...)
    
    for k, v in pairs(self) do
        self[k] = v:transform(...)
    end
    
    return self
end

function Tree:prune()
    -- self:clean()

    local n_subkeys = 0
    self:foreachv(function(sub_t)
        n_subkeys = n_subkeys +  #sub_t:keys()
    end)

    if n_subkeys == 0 then
        return self:keys()
    else
        return self:transformv(function(v) return v:prune() end)
    end
end

function Tree:__tostring()
    return Tree._tostring(Tree(self):prune()):join("\n")
end

function Tree._tostring(t)
    if t:is_a(List) then
        return t:sorted()
    else
        local lines = List()
        t:keys():sorted():foreach(function(k)
            lines:append(k)
            
            local k_pad = string.rep(" ", #k)
            Tree._tostring(t[k]):foreach(function(subline)
                lines:append(k_pad .. subline)
            end)
        end)

        return lines
    end
end

return Tree
