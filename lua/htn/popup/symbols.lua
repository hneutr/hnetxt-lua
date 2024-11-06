local popup = require("htn.popup")
local symbols = require("htn.ui.symbols")

local Popup = setmetatable({}, popup.Popup)
Popup.__index = Popup
Popup.name = "symbols"
Popup.keymap = {
    ["<CR>"] = "select",
    ["<C-l>"] = "select",
    ["<C-h>"] = "enter_parent",
    ["<C-r>"] = "enter_root",
}

--------------------------------------------------------------------------------
--                                   Symbol                                   --
--------------------------------------------------------------------------------
local Symbol = setmetatable({}, popup.Item)
Symbol.__index = Symbol

function Symbol:init(args)
    self.string, self.desc = unpack(args)
end

function Symbol:choice_string()
    if self.desc then
        return self.string .. " " .. self.desc
    end

    return self.string
end

function Symbol:fuzzy_string()
    return self.desc and self.desc or self.string
end

function Symbol:highlight(line)
    if self.desc then
        local start_col = #self.string + 1
        local stop_col = start_col + #self.desc
        self.ui.components.choices:add_highlight("Comment", line, start_col, stop_col)
    end
end

function Symbol:select()
    self.ui:close()
    vim.api.nvim_input(self.string)
end

--------------------------------------------------------------------------------
--                                 SymbolGroup                                --
--------------------------------------------------------------------------------
local SymbolGroup = setmetatable({}, popup.Item)
SymbolGroup.__index = SymbolGroup

function SymbolGroup:select()
    self.ui.components.cursor.index = 1
    self.ui.path:append(self.string)
    self.ui:clear_input()
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

function Choices:get_items()
    local items = symbols()

    self.ui.path:foreach(function(part) items = items[part] end)

    local ItemClass = SymbolGroup

    if #items > 0 then
        ItemClass = Symbol
        items = List(items)
    else
        ItemClass = SymbolGroup
        items = Dict.keys(items):sorted()
    end

    items:transform(function(item) return ItemClass:new(self.ui, item) end)

    items = self:fuzzy_filter(items)

    return items
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
Popup.Choices = Choices
Popup.Prompt = Prompt

function Popup:init()
    self.path = List()
end

function Popup:select()
    self.components.cursor:get():select()
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
