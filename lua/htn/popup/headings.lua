local ui = require("htn.ui")
local popup = require("htn.popup")

local Heading = require("htl.text.Heading")

local Popup = setmetatable({}, popup.Popup)
Popup.__index = Popup
Popup.name = "headings"
Popup.keymap = {
    ["<CR>"] = "goto_selection",

    ["<C-l>"] = "enter_selection",
    ["<C-h>"] = "enter_parent",
    ["<C-r>"] = "enter_root",

    ["<C-1>"] = "filter_h1",
    ["<C-2>"] = "filter_h2",
    ["<C-3>"] = "filter_h3",
    ["<C-4>"] = "filter_h4",
    ["<C-5>"] = "filter_h5",
    ["<C-6>"] = "filter_h6",
}

Popup.data = Dict()

--------------------------------------------------------------------------------
--                                   Prompt                                   --
--------------------------------------------------------------------------------
local Prompt = setmetatable({}, popup.Prompt)
Prompt.__index = Prompt

function Prompt:title()
    return string.format(
        " %s ",
        self.ui.parent and self.ui.parent ~= 0 and self.ui.elements[self.ui.parent].str or "headings"
    )
end

function Prompt:get_line()
    local line = "> "

    if self.ui.level < #Heading.levels then
        line = string.format("[%d] %s", self.ui.level, line)
    end

    return line
end

function Prompt:highlight_line()
    if self.ui.level < #Heading.levels then
        self:add_highlight(Heading.levels[self.ui.level].hl_group, 0, 1, 2)
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  choices                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Choices = setmetatable({}, popup.Choices)
Choices.__index = Choices

function Choices:filter()
    if self.ui.nearest then
        local line = self.ui.nearest
        self.ui.nearest = false
        self.ui.elements:foreach(function(e) self.ui.parent = e.line <= line and e.index or self.ui.parent end)
    end

    self.ui.parent = self.ui.parent or 0
    local pattern = ui.get_cursor_line()

    self.elements = self.ui.elements:filter(function(e)
        local result = true
        result = result and e.parents:contains(self.ui.parent)
        result = result and e.level.n <= self.ui.level

        if #pattern > 0 then
            result = result and MiniFuzzy.match(pattern, e.text).score > 0
        end

        return result
    end)
end

function Choices:update()
    self:filter()

    local levels = #self.elements > 0 and self.elements:map(function(e) return e.level.n end)
    local min_level = math.min(unpack(levels or {0}))

	vim.api.nvim_buf_set_lines(
        self.buffer,
        0,
        -1,
        true,
        self.elements:map(function(element)
            return string.format(
                "%s%s",
                string.rep("  ", element.level.n - min_level),
                element.text
            ):rpad(self.ui.width, " ")
        end)
    )

    self:clear_highlights()

    for i, element in ipairs(self.elements) do
        self:add_highlight(element.level.hl_group, i - 1, 0, -1)
    end
end


--------------------------------------------------------------------------------
--                                   Cursor                                   --
--------------------------------------------------------------------------------
local Cursor = setmetatable({}, popup.Cursor)
Cursor.__index = Cursor

function Cursor:get_hl_group()
    return self.ui.components.choices.elements[self.index].level.bg_hl_group
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------

Popup.Choices = Choices
Popup.Cursor = Cursor
Popup.Prompt = Prompt


function Popup:init(args)
    self.level = args.level or #Heading.levels
    self.parent = 0
    self.nearest = args.nearest and ui.get_cursor().row
    self.elements = self:get_elements()

    self.actions = {}
    for level = 1, #Heading.levels do
        self.actions[string.format("filter_h%d", level)] = function()
            self.level = self.level ~= level and level or #Heading.levels
            self:update()
        end
    end
end

function Popup:get_elements()
    local key = tostring(self.source.buffer)
    local data = self.data[key] or {}

    data.elements = data.elements or ui.headings.get()
    data.watch_autocmd = data.watch_autocmd or vim.api.nvim_create_autocmd(
        "BufModifiedSet",
        {
            buffer = self.source.buffer,
            callback = function() self.data[key].elements = nil end,
        }
    )

    self.data[key] = data

    return data.elements
end

function Popup:goto_selection()
    self:close()
    ui.set_cursor({row = self.components.cursor:get().line})
end

function Popup:enter_selection()
    self.parent = self.components.cursor:get().index
    self.components.cursor.index = 1
    self:update()
end

function Popup:enter_parent()
    if self.parent and self.parent ~= 0 then
        local parents = self.elements[self.parent].parents
        self.parent = parents[#parents]
        self:update()
    end
end

function Popup:enter_root()
    self.parent = 0
    self:update()
end

return {
    open_all = function() return Popup:new() end,
    open_nearest = function() return Popup:new({nearest = true}) end,
    open_1 = function() return Popup:new({level = 1}) end,
    open_2 = function() return Popup:new({level = 2}) end,
    open_3 = function() return Popup:new({level = 3}) end,
    open_4 = function() return Popup:new({level = 4}) end,
    open_5 = function() return Popup:new({level = 5}) end,
    open_6 = function() return Popup:new({level = 6}) end,
}
