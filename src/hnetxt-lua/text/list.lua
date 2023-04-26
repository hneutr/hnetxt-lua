table = require("hneutil.table")
string = require("hneutil.string")
local Object = require("hneutil.object")
local Config = require("hnetxt-lua.config")

--------------------------------------------------------------------------------
--                                                                            --
--                                    Line                                    --
--                                                                            --
--------------------------------------------------------------------------------
Line = Object:extend()
Line.defaults = {
    text = '',
    line_number = 0,
    indent = '',
}
Line.regex = "^(%s*)(.*)$"

function Line:new(args)
    self = table.default(self, args or {}, self.defaults)
end

function Line:write()
    BufferLines.set({start_line = self.line_number, replacement = {tostring(self)}})
end

function Line:__tostring()
    return self.indent .. self.text
end

function Line:merge(other)
    self.text = self.text:rstrip() .. " " .. other.text:lstrip()
end

function Line.get_if_str_is_a(str, line_number)
    local indent, text = str:match(Line.regex)
    return Line({text = text, line_number = line_number, indent = indent})
end

--------------------------------------------------------------------------------
--                                  ListLine                                  --
--------------------------------------------------------------------------------
ListLine = Line:extend()
ListLine.defaults = {
    text = '',
    indent = '',
    line_number = 0,
    sigil = '-',
    -- toggle_key = '',
    -- highlight = true,
    -- highlights = {
    --     sigil = {fg = "blue"},
    --     text = {},
    -- },
    -- toggle = {to = 'bullet'},
    fold = false,
}
ListLine.style = {
    sigil = {
        pattern = [[^\s*STR\s]],
        cmd = [[syn match KEY /PATTERN/ contained]],
    },
    text = {
        pattern = [[start="SIGIL_PATTERN\+" end="$"]],
        cmd = [[syn region KEY PATTERN containedin=ALL contains=SIGIL_KEY,mkdLink]],
    },
}
ListLine.toggle_mapping_rhs = [[:lua require('hnetxt-nvim.text.list').Parser():toggle('MODE', 'NAME')<cr>]]

function ListLine:new(args)
    ListLine.super.new(self, args)
end

function ListLine:__tostring()
    return self.indent .. self.sigil .. " " .. self.text
end

function ListLine.get_sigil_pattern(sigil)
    return "^(%s*)" .. string.escape(sigil) .. "%s(.*)$"
end

function ListLine.get_if_str_is_a(str, line_number)
    return ListLine._get_if_str_is_a(str, line_number, ListLine)
end

function ListLine._get_if_str_is_a(str, line_number, ListLineClass)
    local indent, text = str:match(ListLineClass.get_sigil_pattern(ListLineClass.defaults.sigil))
    if indent and text then
        return ListLineClass({text = text, indent = indent, line_number = line_number})
    end
end

function ListLine.get_class(name)
    local settings = Config.get("list").types[name]
    settings.name = name

    local ListClass
    if name == 'number' then
        ListClass = NumberedListLine
    else
        ListClass = ListLine:extend()
    end

    ListClass.defaults = table.default(settings, ListClass.defaults)

    ListClass.get_if_str_is_a = function(str, line_number)
        return ListClass._get_if_str_is_a(str, line_number, ListClass)
    end

    return ListClass
end

--------------------------------------------------------------------------------
--                              NumberedListLine                              --
--------------------------------------------------------------------------------
NumberedListLine = ListLine:extend()
NumberedListLine.pattern = "^(%s*)(%d+)%.%s(.*)$"
NumberedListLine.defaults = table.default({number = 1, ListClass = 'number'}, ListLine.defaults)

function NumberedListLine:__tostring()
    return self.indent .. self.number .. '. ' .. self.text
end

function NumberedListLine._get_if_str_is_a(str, line_number)
    local indent, number, text = str:match(NumberedListLine.pattern)

    if indent and number and text then
        return NumberedListLine({
            number = tonumber(number),
            text = text,
            indent = indent,
            line_number = line_number,
        })
    end
end

--------------------------------------------------------------------------------
--                                   Parser                                   --
--------------------------------------------------------------------------------
Parser = Object:extend()
Parser.default_types = Config.get("list").default_types

function Parser:new(additional_types)
    self.types = table.list_extend({}, self.default_types)

    for _, additional_type in ipairs(additional_types or {}) do
        if not table.list_contains(self.types, additional_type) then
            self.types[#self.types + 1] = additional_type
        end
    end

    self.classes = {}
    for _, type_name in ipairs(self.types) do
        self.classes[type_name] = ListLine.get_class(type_name)
    end
end

function Parser:parse_line(str, line_number)
    for _, Class in pairs(self.classes) do
        local line = Class.get_if_str_is_a(str, line_number)

        if line then
            return line
        end
    end

    return Line.get_if_str_is_a(str, line_number)
end

function Parser:parse(raw_lines)
    self.lines = {}
    for i, line in ipairs(raw_lines) do
        table.insert(self.lines, self:parse_line(line, i))
    end

    return self.lines
end

-- function Parser:join_lines()
--     local cursor_pos  = vim.api.nvim_win_get_cursor(self.buffer_id)
--     local first_line_number = cursor_pos[1] - 1
--     local second_line_number = first_line_number + 1

--     local lines = BufferLines.get({
--         buffer = self.buffer_id,
--         start_line = first_line_number,
--         end_line = second_line_number + 1,
--     })

--     if vim.tbl_count(lines) ~= 2 then
--         return
--     end

--     local first = self:parse_line(lines[1], first_line_number)
--     local second = self:parse_line(lines[2], second_line_number)

--     first:merge(second)

--     BufferLines.set({
--         buffer = self.buffer_id,
--         start_line = first_line_number,
--         end_line = second_line_number + 1,
--         replacement = {tostring(first)}
--     })
-- end

-- function Parser:map_toggles(lhs_prefix)
--     for _, Class in pairs(self.classes) do
--         Class():map_toggle(lhs_prefix)
--     end
-- end

-- function Parser:toggle(mode, toggle_line_class_name)
--     self.lines = self:parse(BufferLines.selection.get({mode = mode}))

--     local new_line_class = Parser:get_new_line_class(self.lines, toggle_line_class_name)

--     if new_line_class then
--         Parser.set_selected_lines({mode = mode, lines = self.lines, new_line_class = new_line_class})
--     end
-- end

-- function Parser.set_selected_lines(args)
--     args = _G.default_args(args, {mode = 'n', lines = {}, new_line_class = nil})

--     local new_lines = {}
--     for i, line in ipairs(args.lines) do
--         line = args.new_line_class({text = line.text, indent = line.indent, line_number = line.line_number})
--         table.insert(new_lines, tostring(line))
--     end

--     return BufferLines.selection.set({mode = args.mode, replacement = new_lines})
-- end

-- function Parser.get_min_indent_line(lines)
--     local min_indent, min_indent_line = 1000, nil
--     for _, line in ipairs(lines) do
--         if line.indent:len() < min_indent then
--             min_indent = line.indent:len()
--             min_indent_line = line
--         end
--     end

--     return min_indent_line
-- end

-- function Parser:get_new_line_class(lines, toggle_line_type_name)
--     local min_indent_line = Parser.get_min_indent_line(lines)

--     if min_indent_line then
--         if min_indent_line.name == toggle_line_type_name then
--             return ListLine.get_class(min_indent_line.toggle.to)
--         else
--             return ListLine.get_class(toggle_line_type_name)
--         end
--     end
-- end

-- function Parser:continue()
--     local chars = {}
--     for name, Class in pairs(self.classes) do
--         table.insert(chars, Class.defaults.sigil)
--     end

-- 	local current_line = vim.fn.getline(vim.fn.line("."))
--     current_line = current_line:match("%s*(.*)")

-- 	local preceding_line = vim.fn.getline(vim.fn.line(".") - 1)

--     if preceding_line:match("^%s*%d+%.%s") then
-- 		local next_list_index = preceding_line:match("%d+") + 1
-- 		vim.fn.setline(".", preceding_line:match("^%s*") .. next_list_index .. ". ")
--         vim.api.nvim_input("<esc>A")
--     elseif vim.tbl_count(chars) > 0 then
--         for _, char in ipairs(chars) do
--             local pattern = "^%s*" .. _G.escape(char) .. "%s"
--             local matched_content = preceding_line:match(pattern)
--             if matched_content then
--                 vim.fn.setline(".", matched_content .. current_line)
--                 vim.api.nvim_input("<esc>A")
--                 return
--             end
--         end
-- 	end
-- end

-- function add_syntax_highlights()
--     for name, Class in pairs(Parser().classes) do
--         Class():add_syntax_highlighting()
--     end
-- end


return {
    Line = Line,
    ListLine = ListLine,
    NumberedListLine = NumberedListLine,
    Parser = Parser,
    -- add_syntax_highlights = add_syntax_highlights,
}

