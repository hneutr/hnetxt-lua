local Divider = require("htl.text.divider")
local Header = require("htl.text.header")

require("htn.text.list").add_syntax_highlights()
require("htn.ui.fold").add_syntax_highlights()

local Color = require("hn.color")

local elements = Dict(Conf.syntax)

List.from(
    Header.headers(),
    Divider.dividers(),
    {Divider("large", "metadata")}
):foreach(function(e)
    elements:update(e:syntax())
end)

elements:foreach(Color.add_to_syntax)
