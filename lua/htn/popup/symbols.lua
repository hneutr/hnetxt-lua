local ui = require("htn.ui")
local popup = require("htn.popup")
local symbols = require("htn.ui.symbols")

local Popup = setmetatable({}, popup.Popup)
Popup.__index = Popup
Popup.name = "symbols"
Popup.keymap = {
    ["<CR>"] = "insert_or_enter_selection",
    ["<C-l>"] = "insert_or_enter_selection",
    ["<C-h>"] = "enter_parent",
    ["<C-r>"] = "enter_root",
}

--------------------------------------------------------------------------------
--                                                                            --
--                                   Symbol                                   --
--                                                                            --
--------------------------------------------------------------------------------
local Symbol = {}
Symbol.__index = Symbol
Symbol.name = 'symbol'

function Symbol:new(args)
    local instance = setmetatable({}, self)
    instance.string, instance.desc = unpack(args)
    return instance
end

function Symbol:__tostring()
    local s = self.string

    if self.desc then
        s = s .. " " .. self.desc
    end

    return s
end

function Symbol:highlight_cols()
    if self.desc then
        local start = #self.string + 1
        local stop = start + #self.desc
        return {start = start, stop = stop}
    end

    return
end

function Symbol:match(pattern)
    return MiniFuzzy.match(pattern, self.desc and self.desc or self.string).score > 0
end

--------------------------------------------------------------------------------
--                                                                            --
--                                SymbolGroup                                 --
--                                                                            --
--------------------------------------------------------------------------------
local SymbolGroup = {}
SymbolGroup.__index = SymbolGroup
SymbolGroup.name = "group"

function SymbolGroup:new(string)
    local instance = setmetatable({}, self)
    instance.string = string
    return instance
end

function SymbolGroup:__tostring() return self.string end

function SymbolGroup:highlight_cols() return end

function SymbolGroup:match(pattern)
    return MiniFuzzy.match(pattern, self.string).score > 0
end

--------------------------------------------------------------------------------
--                                   Prompt                                   --
--------------------------------------------------------------------------------
local Prompt = setmetatable({}, popup.Prompt)
Prompt.__index = Prompt

function Prompt:title()
    if #self.ui.path == 0 then
        return ""
    end

    return " " .. self.ui.path:join(".") .. " "
end

--------------------------------------------------------------------------------
--                                   Choices                                  --
--------------------------------------------------------------------------------
local Choices = setmetatable({}, popup.Choices)
Choices.__index = Choices

function Choices:filter()
    local elements = symbols()

    self.ui.path:foreach(function(part) elements = elements[part] end)

    if #elements > 0 then
        self.element_class = Symbol
        elements = List(elements)
    else
        self.element_class = SymbolGroup
        elements = Dict.keys(elements):sorted()
    end

    elements:transform(function(element) return self.element_class:new(element) end)

    local pattern = ui.get_cursor_line()

    if #pattern > 0 then
        elements = elements:filter(function(element) return element:match(pattern) end)
    end

    self.elements = elements
end

function Choices:update(state)
	self:filter()

	vim.api.nvim_buf_set_lines(
        self.buffer,
        0,
        -1,
        true,
        self.elements:map(function(element)
            local str = tostring(element)
            return str .. string.rep(" ", self.ui.width - #vim.str_utf_pos(str))
        end)
    )

    self:clear_highlights()

    if self.element_class.name == 'symbol' then
        for i, element in ipairs(self.elements) do
            local cols = element:highlight_cols()

            if cols then
                self:add_highlight("Comment", i - 1, cols.start, cols.stop)
            end
        end
    end
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
Popup.Choices = Choices
Popup.Prompt = Prompt

function Popup:init()
    self.path = List()
end

function Popup:insert_or_enter_selection()
    local element = self.components.cursor:get()

    if element.name == 'group' then
        self.path:append(tostring(element))
        self:clear_input()
    else
        self:close()
        vim.api.nvim_input(element.string)
    end
end

function Popup:enter_parent()
    if #self.path > 0 then
        self.path:pop()
        self:clear_input()
    end
end

function Popup:enter_root()
    if #self.path > 0 then
        self.path = List()
        self:clear_input()
    end
end

return function() Popup:new() end
