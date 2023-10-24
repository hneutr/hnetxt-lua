local Color = require("hn.color")
local Header = require("htl.text.header")

function Header.add_syntax_highlights()
    Header.by_size():foreach(function(size, header)
        header.line_templates:foreachk(function(line_type)
            Color.add_to_syntax(
                size .. "Header" .. line_type,
                {
                    string = header:get_pattern(line_type):gsub("%%s.*", "\\s"),
                    color = header.color
                }
            )
        end)
    end)
end

return Header
