local List = require("hl.List")
local Dict = require("hl.Dict")
local class = require("pl.class")
local Config = require("htl.config")

class.NHeader()
NHeader.config = Config.get("new_header")

function NHeader:_init(args)
    self = Dict.update(self, args or {}, {size = NHeader.config.default_size, content = ''})
    self = Dict.update(self, self.config.sizes[self.size])
end

function NHeader:get_top()
    return self.top.left .. self.fill.horizontal:rep(self.width - 2) .. self.top.right
end

function NHeader:get_bottom()
    return self.bottom.left .. self.fill.horizontal:rep(self.width - 2) .. self.bottom.right
end

function NHeader:get_middle()
    local middle = self.fill.vertical .. self.content
    -- middle = middle .. string.rep(" ", self.width - middle:len() + 1) .. self.fill.vertical
    return middle
end

function NHeader:__tostring()
    return List({
        self:get_top(),
        self:get_middle(),
        self:get_bottom(),
    }):join("\n")
end

return NHeader
