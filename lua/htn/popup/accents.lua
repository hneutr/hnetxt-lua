local popup = require("htn.popup")

local Popup = Class({
    name = "accents",
    conf = Conf.accents,
    dimensions = {
        height = 18,
        width = 19,
    },
}, popup.Popup)

--------------------------------------------------------------------------------
--                                   Letter                                   --
--------------------------------------------------------------------------------
local Letter = Class({
    cursor_highlight_group = "Text",
    accent_highlight = "CursorLineFold",
}, popup.Item)

function Letter:init(args)
    self.letter, self.accents = unpack(args)
    self.letters = {lower = self.letter, upper = self.letter:upper()}
end

function Letter:choice_string()
    local key = self.ui.pattern_is_uppercase and "upper" or "lower"
    return self.letters[key] .. " " .. self.accents[key]:join(" ")
end

function Letter:fuzzy_string()
    return self.letter
end

function Letter:highlight(line)
    self.ui.choices:add_highlight(self.accent_highlight, line, 2, self:choice_string():len())
end

function Letter:select(index)
    local key = self.ui.pattern_is_uppercase and "upper" or "lower"
    local char = #self.accents[key] >= index and self.accents[key][index] or self.letters[key]

    self.ui:close()
    vim.api.nvim_input(char)
end

--------------------------------------------------------------------------------
--                                   Choices                                  --
--------------------------------------------------------------------------------
local Choices = Class({}, popup.Choices)

function Choices:update()
    self.items = self.ui.items:filterm("filter")
    self.items:put(self.ui.headline)
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
Popup.Choices = Choices

function Popup:init()
    self.items = List(self.conf:keys():sorted():map(function(letter)
        return Letter:new(self, {letter, self.conf[letter]})
    end))

    local numbers = List()
    for i = 1, 9 do
        numbers:append(tostring(i))
    end

    self.headline = Letter:new(self, {" ", {lower = numbers, upper = numbers}})
    self.headline.accent_highlight = "Text"
end

function Popup:read_input()
    self.pattern_is_uppercase = false

    local pattern = self.pattern

    if not pattern then
        return
    end

    local elements = List(pattern)

    if #elements > 0 then
        local letter = elements[1]

        if letter:upper() == letter then
            self.pattern_is_uppercase = true
            letter = letter:lower()
        end

        self.pattern = letter
    end

    if #elements == 2 then
        self.pattern_index = tonumber(elements[2])
    end
end

function Popup:update()
    self.pattern = vim.api.nvim_get_current_line()
    self.pattern = #self.pattern > 0 and self.pattern or nil

    self:read_input()
    local items = self.items:filterm("filter")

    if #items == 1 and self.pattern_index then
        items[1]:select(self.pattern_index)
    else
        self.components:mapm("update")
    end

    self.update_trigger = nil
end

Popup.open = Popup.update

return function() Popup:new() end
