string = require("hl.string")

local Dict = require("hl.Dict")
local List = require("hl.List")

local Color = require("hn.color")
local BufferLines = require("hn.buffer_lines")
local Config = require("htl.config").get('list')

local TextList = require("htl.text.List")
local Item = require("htl.text.List.Item")

local function toggle(mode, toggle_line_type_name)
    BufferLines.selection.set({
        mode = mode,
        replacement = TextList:convert_lines(
            BufferLines.selection.get({mode = mode}),
            toggle_line_type_name
        ):transform(tostring)
    })
end

local function join()
    local line_number = unpack(vim.api.nvim_win_get_cursor(0))
    line_number = line_number - 1
    
    local lines = vim.api.nvim_buf_get_lines(
        0,
        line_number,
        line_number + 2,
        false
    )

    if #lines == 2 then
        local line = TextList:parse_line(lines[1]):merge(TextList:parse_line(lines[2]))
        local lines = vim.api.nvim_buf_set_lines(
            0,
            line_number,
            line_number + 2,
            false,
            {tostring(line)}
        )
    end
end

local function handle_comment(line, next_line)
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

local function continue(from_command)
    local _, lnum, col = unpack(vim.fn.getcurpos())

    local str = vim.fn.getline('.')
    local next_str = ""

    if not from_command then
        next_str = str:sub(col):strip()
        str = str:sub(1, col - 1):rstrip()
    end

    local line = TextList:parse_line(str)
    local next_line = line:get_next(next_str)

    local line_is_a_comment = handle_comment(line, next_line)

    vim.api.nvim_buf_set_lines(
        0,
        lnum - 1,
        lnum,
        false,
        {tostring(line), tostring(next_line)}
    )

    vim.api.nvim_win_set_cursor(0, {lnum + 1, 0})
    
    if line:is_a(Item) or line_is_a_comment then
        vim.api.nvim_input("<esc>A")
    else
        vim.api.nvim_input("<esc>I")
    end
end

local function get_list_type_configs()
    local type_configs = List()
    Dict(Config.types):foreach(function(name, config)
        type_configs:append(
            Dict.from(
                config, 
                {name = name},
                {
                    highlight = true, 
                    highlights = {
                        sigil = {fg = "blue"},
                        text = {},
                    },
                }
            )
        )
    end)

    return type_configs
end

local function add_syntax_highlights()
    get_list_type_configs():filter(function(config)
        return config.highlight
    end):foreach(function(config)
        local sigil_key = config.name .. "ListItemSigil"
        local sigil_pattern = string.format([[^\s*%s\s]], config.sigil_regex or config.sigil)
        local sigil_cmd = List({
            "syn",
            "match",
            sigil_key,
            string.format([[/%s/]], sigil_pattern),
            "contained"
        }):join(" ")

        vim.cmd(sigil_cmd)
        Color.set_highlight({name = sigil_key, val = config.highlights.sigil})

        local text_key = config.name .. "ListItemText"
        local text_cmd = List({
            "syn",
            "region",
            text_key,
            string.format([[start="%s\+"]], sigil_pattern),
            [[end="$"]],
            "containedin=ALL",
            string.format("contains=%s", sigil_key),
        }):join(" ")

        vim.cmd(text_cmd)
        Color.set_highlight({name = text_key, val = config.highlights.text})
    end)
end

local function map_toggles(lhs_prefix)
    local lhs_prefix = lhs_prefix or ''
    get_list_type_configs():filter(function(config)
        return config.toggle_key
    end):foreach(function(config)
        List({'n', 'v'}):foreach(function(mode)
            vim.keymap.set(
                mode,
                lhs_prefix .. config.toggle_key,
                string.format([[:lua require('htn.text.list').toggle('%s', '%s')<cr>]], mode, config.name),
                {silent = true, buffer = true}
            )
        end)
    end)
end

return {
    join = join,
    continue = continue,
    continue_cmd = [[<cmd>lua require('htn.text.list').continue(true)<cr>]],
    toggle = toggle,
    map_toggles = map_toggles,
    add_syntax_highlights = add_syntax_highlights,
}
