local Header = require("htl.text.header")

function Header:syntax()
    local syntax = {}
    self.line_templates:foreachk(function(line_type)
        syntax[self.size .. "Header" .. line_type] = {
            string = self:get_pattern(line_type):gsub("%%s.*", "\\s"),
            color = self.color,
        }
    end)
    return syntax
end

return Header
