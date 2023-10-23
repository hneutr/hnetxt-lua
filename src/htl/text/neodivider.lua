local Dict = require("hl.Dict")
local List = require("hl.List")
local class = require("pl.class")

local Config = require("htl.config")

class.NDivider()
NDivider.config = Config.get("new_divider")
NDivider.sizes = Config.get("sizes")
NDivider.regex_info = {pre = "^", post = "$"}


function NDivider:_init(size)
    self = Dict.update(self, {size = size}, NDivider.config)
    self = Dict.update(self, self.config[self.size], self.sizes[self.size])
end

function NDivider:__tostring()
    return self.left .. self.fill:rep(self.width - 2) .. self.right
end

function NDivider:regex()
    return "^" .. tostring(self) .. "$"
end

function NDivider:str_is_a(str)
    return str:match(self:regex())
end

function NDivider.dividers()
    return Dict(NDivider.sizes):keys():transform(NDivider)
end

function NDivider.by_size()
    local dividers = Dict()
    Dict(NDivider.sizes):keys():foreach(function(size)
        dividers[size] = NDivider(size)
    end)
    return dividers
end

return NDivider
