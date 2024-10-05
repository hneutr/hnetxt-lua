local BufferLines = require("hn.buffer_lines")

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

function M.handle_comment(line, next_line)
    local comment_string = vim.opt_local.commentstring:get()

    if comment_string ~= nil and #comment_string > 0 then
        comment_string = comment_string:gsub("%%s", "")

        if line.text:startswith(comment_string) then 
            next_line.text = comment_string .. next_line.text 
            return true
        end
    end

    return false
end

function M.continue(from_command)
    local _, lnum, col = unpack(vim.fn.getcurpos())

    local str = vim.fn.getline('.')
    local next_str = ""

    if not from_command then
        next_str = str:sub(col):strip()
        str = str:sub(1, col - 1)
    end

    local line = TextList.parse(str)
    local new_content
    local line_is_a_comment = false
    local new_line_number = lnum

    -- if the current line is a list item and is empty, remove the list item
    -- (double enter → remove list sigil)
    if #line.text == 0 and #next_str == 0 and #tostring(line) > 0 and line:is_a(Item) and not from_command then
        new_content = {line.indent}
    else
        line.text = line.text:rstrip()
        local next_line = line:get_next(next_str)
        line_is_a_comment = M.handle_comment(line, next_line)
        new_content = {tostring(line), tostring(next_line)}
        new_line_number = new_line_number + 1
    end

    vim.api.nvim_buf_set_lines(
        0,
        lnum - 1,
        lnum,
        false,
        new_content
    )

    vim.api.nvim_win_set_cursor(0, {new_line_number, 0})
    
    if line:is_a(Item) or line_is_a_comment then
        vim.api.nvim_input("<esc>A")
    else
        vim.api.nvim_input("<esc>I")
    end
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

function M.change(mode, ...)
    BufferLines.selection.set({
        mode = mode,
        replacement = TextList.change(
            List(BufferLines.selection.get({mode = mode})),
            ...
        )
    })
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
