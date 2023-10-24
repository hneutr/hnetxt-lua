local Color = require("hn.color")
local NDivider = require("htl.text.neodivider")

function NDivider.add_syntax_highlights()
    NDivider.by_size():foreach(function(size, divider)
        Color.add_to_syntax(
            size .. "NDivider",
            {
                string = divider:regex(),
                color = divider.color
            }
        )
    end)

    local metadata_divider = NDivider("large", "metadata")
    Color.add_to_syntax(
        "LargeMetadataNDivider",
        {
            string = metadata_divider:regex(),
            color = metadata_divider.color
        }
    )
end

return NDivider
