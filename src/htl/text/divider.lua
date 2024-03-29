local Dict = require("hl.Dict")
local List = require("hl.List")
local class = require("pl.class")

local Config = require("htl.Config")

class.Divider()
Divider.config = Config.get("divider")
Divider.sizes = Config.get("sizes")

function Divider:_init(size, style)
    self = Dict.update(self, {size = size, style = style}, self.config)
    self = Dict.update(self, self.config[self.style], self.sizes[self.size])
end

function Divider:__tostring()
    return self.left .. self.fill:rep(self.width - 2) .. self.right
end

function Divider:regex()
    return "^" .. tostring(self) .. "$"
end

function Divider:str_is_a(str)
    return str:match(self:regex())
end

function Divider.dividers()
    return Dict(Divider.sizes):keys():transform(Divider)
end

function Divider.by_size()
    local dividers = Dict()
    Dict(Divider.sizes):keys():foreach(function(size)
        dividers[size] = Divider(size)
    end)
    return dividers
end

function Divider.metadata_divider()
    return Divider("large", "metadata")
end

return Divider
