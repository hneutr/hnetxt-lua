local BufferLines = require("hn.buffer_lines")
local ui = require("htn.ui")

local TextList = require("htl.text.List")
local Item = require("htl.text.List.Item")
local Line = require("htl.text.Line")

local M = {}

function M.join()
    local line = unpack(vim.api.nvim_win_get_cursor(0))
    local args = List({0, line - 1, line + 1, false})
    local lines = List(vim.api.nvim_buf_get_lines(unpack(args)))

    if #lines > 1 then
        args:append({tostring(TextList.merge(lines))})
        vim.api.nvim_buf_set_lines(unpack(args))
    end
end

function M.continue_comment(line, next_line)
    local comment_string = vim.opt_local.commentstring:get()

    if comment_string and #comment_string > 0 then
        comment_string = comment_string:gsub("%%s", "")

        if line.text:startswith(comment_string) then 
            next_line.text = comment_string .. next_line.text 
        end
    end
end

function M.continue()
    local cur = ui.get_cursor()
    
    local str = ui.get_cursor_line()
    local next_str = str:sub(cur.col + 1):strip()
    str = str:sub(1, cur.col)

    local line = TextList.parse(str)

    --[[
    double enter → remove list sigil/quote:
    if the current line is an empty:
    - list item: remove the list sigil (keep the quote)
    - quote: remove the quote
    ]]
    if #line.text == 0 and #next_str == 0 and #tostring(line) > 0 then
        if line:is_a(Item) then
            ui.set_cursor_line({line.quote .. line.indent})
        else
            ui.set_cursor_line({line.indent})
        end
    else
        line.text = line.text:rstrip()
        local next_line = line:get_next(next_str)
        M.continue_comment(line, next_line)
        ui.set_cursor_line({line, next_line})
        ui.set_cursor({row = cur.row + 1, center = false})
    end

    vim.api.nvim_input("<esc>A")
end

function M.syntax()
    local d = Dict()

    Item.confs:filter(function(conf)
        return conf.highlights
    end):foreach(function(conf)
        local sigil_key = conf.name .. "ListItemSigil"
        local sigil_pattern = string.format([[^\s*%s\s]], conf.sigil_regex or conf.sigil)
        local text_key = conf.name .. "ListItemText"

        d[sigil_key] = {
            val = conf.highlights.sigil,
            cmd = List({
                "syn",
                "match",
                sigil_key,
                string.format([[/%s/]], sigil_pattern),
                "contained"
            }):join(" "),
        }

        d[text_key] = {
            val = conf.highlights.text,
            cmd = List({
                "syn",
                "region",
                text_key,
                string.format([[start="%s\+"]], sigil_pattern),
                [[end="$"]],
                "containedin=ALL",
                string.format("contains=%s", sigil_key),
            }):join(" "),
        }
    end)
    
    return d
end

function M.change(mode, change_type, ...)
    local lines = List(BufferLines.selection.get({mode = mode}))

    BufferLines.selection.set({
        mode = mode,
        replacement = TextList.change(lines, change_type, ...)
    })
    
    if mode == 'v' and change_type == 'indent' then
        vim.api.nvim_input('gv')
        if #lines > 1 then
            vim.api.nvim_input(string.format("%dj", #lines - 1))
        end
    end
end

function M.mappings()
    local mappings = Dict({n = Dict(), v = Dict()})

    Item.confs:foreach(function(conf)
        List({'n', 'v'}):foreach(function(mode)
            mappings[mode][vim.g.list_toggle_prefix .. conf.toggle_key] = string.format(
                [[:lua require('htn.text.list').change('%s', '%s')<cr>]],
                mode,
                conf.name
            )
        end)
    end)
    
    mappings.n['>>'] = string.format(M.indent_command, 'n', 1)
    mappings.v['>'] = string.format(M.indent_command, 'v', 1)
    mappings.n['<<'] = string.format(M.indent_command, 'n', 0)
    mappings.v['<'] = string.format(M.indent_command, 'v', 0)

    return mappings
end

M.indent_command = [[:lua require('htn.text.list').change('%s', 'indent', %d)<cr>]]
M.continue_cmd = [[<cmd>lua require('htn.text.list').continue(true)<cr>]]

return M
