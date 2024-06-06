local M = class()
M.name = "divider"

function M:_init(args)
    self = Dict.update(self, args or {}, Conf.divider)
    self = Dict.update(self, Conf.divider[self.style], Conf.sizes[self.size])
end

function M:__tostring()
    return self.left .. self.fill:rep(self.width - 2) .. self.right
end

function M:regex()
    return "^" .. tostring(self) .. "$"
end

function M:str_is_a(str)
    return str:match(self:regex())
end

function M.dividers()
    return Dict(Conf.sizes):keys():transform(function(size) return M({size = size}) end)
end

function M.metadata_divider()
    return M({size = "large", style = "metadata"})
end

function M:syntax()
    return {
        [self.size .. self.style .. "Divider"] = {string = self:regex(), color = self.color}
    }
end

return M
