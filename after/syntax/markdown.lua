local Dict = require("hl.Dict")
local List = require("hl.List")

local Divider = require("htn.text.divider")
local Header = require("htn.text.header")

require("htn.text.list").add_syntax_highlights()
require("htn.ui.fold").add_syntax_highlights()

local Color = require("hn.color")
local Config = require("htl.Config")
local Syntax = Config.get('syntax')

local syntax_elements = Dict(Syntax)

List.from(
    Header.headers(),
    Divider.dividers(),
    {Divider("large", "metadata")}
):foreach(function(e)
    syntax_elements:update(e:syntax())
end)

syntax_elements:foreach(Color.add_to_syntax)
