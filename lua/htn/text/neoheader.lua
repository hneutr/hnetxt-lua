local Color = require("hn.color")
local class = require("pl.class")

class.NNHeader(require("htl.text.neoheader"))

function NNHeader:add_syntax_highlighting()
    local top, middle, bottom = unpack(tostring(self):split("\n"))
    Color.add_to_syntax(self.size .. "NeoHeaderTop", {string = "^" .. top, color = self.color})
    Color.add_to_syntax(self.size .. "NeoHeaderMiddle", {string = "^" .. middle, color = self.color})
    Color.add_to_syntax(self.size .. "NeoHeaderBottom", {string = "^" .. bottom, color = self.color})
end

function NNHeader.add_syntax_highlights()
    for size, _ in pairs(NNHeader.config.sizes) do
        NNHeader({size = size}):add_syntax_highlighting()
    end
end

return NNHeader
