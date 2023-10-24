local Color = require("hn.color")
local NHeader = require("htl.text.neoheader")

function NHeader.add_syntax_highlights()
    NHeader.by_size():foreach(function(size, header)
        header.line_templates:foreachk(function(line_type)
            Color.add_to_syntax(
                size .. "NeoHeader" .. line_type,
                {
                    string = header:get_pattern(line_type):gsub("%%s.*", "\\s"),
                    color = header.color
                }
            )
        end)
    end)
end

return NHeader
