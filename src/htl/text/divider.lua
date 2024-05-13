local Divider = class()

Divider.config = Conf.divider
Divider.sizes = Conf.sizes

function Divider:_init(size, style)
    self = Dict.update(self, {size = size, style = style}, self.config)
    self = Dict.update(self, self.config[self.style], self.sizes[self.size])
    return self
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

function Divider:syntax()
    return {
        [self.size .. self.style .. "Divider"] = {string = self:regex(), color = self.color}
    }
end

return Divider
