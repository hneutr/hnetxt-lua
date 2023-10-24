local BufferLines = require("hn.buffer_lines")
local Color = require("hn.color")

local Parser = require("htl.text.neoparse")

local M = {}

function M.get_text(lnum)
    local text = BufferLines.line.get({start_line = lnum})
    local whitespace, text = text:match("^(%s*)(.*)")
    return whitespace .. "..."
end

function M.set_line_info()
    local parser = Parser()
    local lines = BufferLines.get()
    vim.b.fold_levels = parser:get_fold_levels(lines)
    vim.b.header_indexes = parser:get_header_indexes(lines)
end

function M.get_indic(lnum)
    if not vim.b.fold_levels then
        M.set_line_info()
    end

    return vim.b.fold_levels[lnum]
end

function M.add_syntax_highlights()
    Color.set_highlight({name = "Folded", val = {fg = 'pink'}})
end

function M.jump_to_header(direction)
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local header_indexes = List(vim.b.header_indexes)
    header_indexes:put(1)
    header_indexes:append(vim.fn.line('$'))

    local candidates

    if direction == 1 then
        candidates = header_indexes:filter(function(hi) return hi > lnum end)
    else
        candidates = header_indexes:filter(function(hi) return hi < lnum end):reverse()
    end

    if #candidates > 0 then
        vim.api.nvim_win_set_cursor(0, {candidates[1], 0})
    end
end

return M
