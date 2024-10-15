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

function M.add_line()
    local line = TextList.parse(ui.get_cursor_line())

    ui.set_cursor_line({line, line:get_next()})
    ui.set_cursor({row = ui.get_cursor().row + 1, center = false})
    vim.api.nvim_input("<esc>A")
end

function M.continue()
    local cur = ui.get_cursor()
    
    local str = ui.get_cursor_line()
    local next_str = str:sub(cur.col + 1):strip()
    local next_str_len = #next_str
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
            str = line.quote .. line.indent
        elseif #line.quote > 0 then
            str = line.indent
        else
            str = ""
        end

        next_str = nil
    else
        line.text = line.text:rstrip()
        str = tostring(line)
        next_str = tostring(line:get_next(next_str))
    end

    ui.set_cursor_line({str, next_str})

    local command = "A"
    if next_str then
        ui.set_cursor({
            row = cur.row + 1,
            col = #next_str - next_str_len,
            center = false,
        })

        command = "i"
    end

    vim.api.nvim_input("<esc>" .. command)
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
    local lines = TextList.change(
        ui.get_selection({mode = mode}),
        change_type,
        ...
    )

    ui.set_selection({mode = mode, lines = lines})
    
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

return M
