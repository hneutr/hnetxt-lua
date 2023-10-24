local Color = require("hn.color")
local Divider = require("htl.text.divider")

function Divider.add_syntax_highlights()
    Divider.by_size():foreach(function(size, divider)
        Color.add_to_syntax(
            size .. "Divider",
            {
                string = divider:regex(),
                color = divider.color
            }
        )
    end)

    local metadata_divider = Divider("large", "metadata")
    Color.add_to_syntax(
        "LargeMetadataDivider",
        {
            string = metadata_divider:regex(),
            color = metadata_divider.color
        }
    )
end

return Divider
