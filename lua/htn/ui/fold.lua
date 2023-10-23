local BufferLines = require("hn.buffer_lines")
local Color = require("hn.color")

local Parser = require("htl.text.neoparse")

local M = {}

function M.get_text(lnum)
    local text = BufferLines.line.get({start_line = lnum})
    local whitespace, text = text:match("^(%s*)(.*)")
    return whitespace .. "..."
end

function M.set_fold_levels()
    vim.b.fold_levels = Parser():get_fold_levels(BufferLines.get())
end

function M.get_indic(lnum)
    if not vim.b.fold_levels then
        M.set_fold_levels()
    end

    return vim.b.fold_levels[lnum]
end

function M.add_syntax_highlights()
    Color.set_highlight({name = "Folded", val = {fg = 'pink'}})
end

return M
