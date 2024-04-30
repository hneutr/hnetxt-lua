local class = require("pl.class")
local Dict = require("hl.Dict")

local M = {}

DefaultDict = function(default)
    if not M[default] then
        local D = class(Dict)
        D.__index = function(self, key)
            if type(key) == 'table' then
                key = tostring(key)
            end
            
            if D[key] then
                return D[key]
            end
            
            local val = rawget(self, key)
            if val == nil then
                rawset(self, key, default())
                val = rawget(self, key)
            end
            
            return val
        end

        M[default] = D
    end

    return M[default]()
end

return DefaultDict
