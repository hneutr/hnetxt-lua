local popup = require("htn.popup")
local symbols = require("htn.ui.symbols")

local Popup = Class({
    name = "symbols",
    keymap = {
        ["<CR>"] = "select",
        ["<C-l>"] = "select",
        ["<C-h>"] = "enter_parent",
        ["<C-r>"] = "enter_root",
    },
}, popup.Popup)

--------------------------------------------------------------------------------
--                                   Symbol                                   --
--------------------------------------------------------------------------------
local Symbol = Class({}, popup.Item)

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
        self.ui.choices:add_highlight("Comment", line, start_col, stop_col)
    end
end

function Symbol:select()
    self.ui:close()
    vim.api.nvim_input(self.string)
end

--------------------------------------------------------------------------------
--                                 SymbolGroup                                --
--------------------------------------------------------------------------------
local SymbolGroup = Class({}, popup.Item)

function SymbolGroup:select()
    self.ui.cursor.index = 1
    self.ui.path:append(self.string)
    self.ui:clear_input()
end

--------------------------------------------------------------------------------
--                                   Choices                                  --
--------------------------------------------------------------------------------
local Choices = Class({}, popup.Choices)

function Choices:update()
    local items = symbols()

    self.ui.path:foreach(function(part) items = items[part] end)

    local ItemClass = Symbol

    if #items == 0 then
        ItemClass = SymbolGroup
        items = Dict.keys(items):sorted()
    end

    self.items = List(items):map(function(item) return ItemClass:new(self.ui, item) end):filterm("filter")
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
Popup.Choices = Choices

function Popup:init()
    self.path = List()
end

function Popup:title() return #self.path > 0 and self.path:join(".") end

function Popup:select()
    self.cursor:get():select()
end

function Popup:clear_input()
    self.input:set_lines({""})
    self.pattern = nil
    self:update()
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
