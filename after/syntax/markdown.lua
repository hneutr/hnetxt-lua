local Color = require("hn.color")
local Metadata = require("htl.Metadata")

local function get_syntax()
    if not vim.g.htn_syntax then
        local elements = Dict(Conf.syntax)
        elements:update(require("htn.text.list").syntax())

        Metadata.Relations:foreach(function(e)
            elements:update(e:syntax())
        end)
        
        vim.g.htn_syntax = elements
        return elements
    end

    return Dict(vim.g.htn_syntax)
end

get_syntax():foreach(Color.add_to_syntax)

vim.cmd([[highlight clear SpellLocal]])
vim.cmd([[highlight clear SpellCap]])
