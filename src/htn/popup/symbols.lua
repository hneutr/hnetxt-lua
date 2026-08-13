local popup = require("htn.popup")
local symbols = require("htn.ui.symbols")

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
    self.ui.input:clear()
    self.ui:update()
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

    self.items = List(items):map(item -> ItemClass:new(self.ui, item)):filterm("filter")
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
local Popup = Class({
    name = "symbols",
    Choices = Choices,
}, popup.Popup)

function Popup:init()
    self.path = List()
end

function Popup:title() return #self.path > 0 and self.path:join(".") end

-----------------------------------[ actions ]----------------------------------
Popup.keymap = List({
    {
        lhs = "<CR>",
        desc = "enter/select",
        callback = ui -> ui.cursor.item:select(),
    },
    {
        lhs = "<C-l>",
        desc = "enter/select",
        callback = ui -> ui.cursor.item:select(),
    },
    {
        lhs = "<C-h>",
        desc = "enter parent",
        callback = function(ui)
            if #ui.path > 0 then
                ui.path:pop()
                ui.input:clear()
                ui:update()
            end
        end,
    },
    {
        lhs = "<C-r>",
        desc = "enter root",
        callback = function(ui)
            if #ui.path > 0 then
                ui.path = List()
                ui.input:clear()
                ui:update()
            end
        end,
    },
})

return function() Popup:new() end
