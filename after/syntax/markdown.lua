local Color = require("hn.color")
local Divider = require("htl.text.divider")
local Header = require("htl.text.header")
local TaxonomyParser = require("htl.Taxonomy.Parser")

local function get_syntax()
    if not vim.g.htn_syntax then
        local elements = Dict(Conf.syntax)
        elements.Folded = {color = 'blue'}
        elements:update(require("htn.text.list").syntax())

        List.from(
            Header.headers(),
            Divider.dividers(),
            TaxonomyParser.Relations,
            {Divider("large", "metadata")},
            {}
        ):foreach(function(e)
            elements:update(e:syntax())
        end)
        
        vim.g.htn_syntax = elements
        return elements
    end

    return Dict(vim.g.htn_syntax)
end

get_syntax():foreach(Color.add_to_syntax)
