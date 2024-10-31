local ui = require("htn.ui")
local symbols = require("htn.ui.symbols")

local M = {}
M.__index = M

M.opts = {
    keymap = {
        ["<C-c>"] = "close",

        ["<C-n>"] = "cursor_down",
        ["<C-p>"] = "cursor_up",
        ["<Down>"] = "cursor_down",
        ["<Up>"] = "cursor_up",

        ["<C-f>"] = "cursor_page_down",
        ["<C-b>"] = "cursor_page_up",

        ["<CR>"] = "insert_or_enter_selection",
        ["<C-l>"] = "insert_or_enter_selection",
        ["<C-h>"] = "enter_parent",
        ["<C-r>"] = "enter_root",
    },
    window = {
        width = 80,
        border = {"╭", "─", "╮", "│", "┤", "─", "├", "│"},
    },
}

-- function M.get_symbols()
--     local raw = require("htn.ui.symbols")
--     local d = Dict()
--
--     for key, val in
--
-- end

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
--                                                                            --
--                                                                            --
--                                   Window                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Window = {}
Window.__index = Window

function Window:new(buffer, conf)
    local instance = setmetatable({}, self)
    instance.buffer = buffer
	instance.id = vim.api.nvim_open_win(buffer, true, conf)
    return instance
end

function Window:close()
    vim.api.nvim_win_close(self.id, true)
    vim.api.nvim_buf_delete(self.buffer, {force = true})
end

function Window:update(new_conf)
    local conf = vim.api.nvim_win_get_config(self.id)

    local update = false
    Dict(new_conf):foreach(function(key, val)
        if conf[key] ~= val then
            conf[key] = val
            update = true
        end
    end)

    if update then
        vim.api.nvim_win_set_config(self.id, conf)
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 container                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local UIElement = {}
UIElement.__index = UIElement
UIElement.name = "element"

function UIElement:new(ui)
    local instance = setmetatable({}, self)

    instance.ui = ui

    instance.namespace = vim.api.nvim_create_namespace(string.format("htn.popup.symbols.%s", instance.name))

    instance:init()

    if instance.window_conf then
        instance.buffer = vim.api.nvim_create_buf(false, true)
        instance.window = Window:new(instance.buffer, instance.window_conf)
    end

    return instance
end

function UIElement:close()
    return self.window and self.window:close()
end

function UIElement:init() return end

function UIElement:clear_highlights()
	vim.api.nvim_buf_clear_namespace(self.buffer, self.namespace, 0, -1)
end

function UIElement:add_highlight(group, line, start_col, end_col)
    vim.api.nvim_buf_add_highlight(
        self.buffer,
        self.namespace,
        group,
        line,
        start_col,
        end_col
    )
end

function UIElement:update() return end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    box                                     --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Box = setmetatable({}, UIElement)
Box.__index = Box
Box.name = 'box'

function Box:init()
    local n_rows = vim.go.lines
    local height = math.floor(n_rows / 2)

    local row = math.floor((n_rows - height) / 2)

    local n_cols = vim.go.columns
    local col = math.floor((n_cols - M.opts.window.width) / 2 - 1)

    self.window_conf = {
        relative = "editor",
        width = M.opts.window.width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
        style = "minimal",
        noautocmd = true,
    }
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   prompt                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Prompt = setmetatable({}, UIElement)
Prompt.name = "prompt"
Prompt.__index = Prompt

function Prompt:init()
    self.window_conf = {
        relative = "win",
        win = self.ui.components.box.window.id,
        width = M.opts.window.width,
        height = 1,
        row = -2,
        col = -1,
        -- title = self:title(),
        -- title_pos = "center",
        border = M.opts.window.border,
        noautocmd = true,
        style = "minimal",
    }
end

function Prompt:title()
    if #self.ui.path == 0 then
        return ""
    end

    return " " .. self.ui.path:join(".") .. " "
end

function Prompt:update()
	vim.api.nvim_buf_set_lines(self.buffer, 0, 1, true, {"> "})
    self.window:update({title = self:title(), title_pos = "center"})
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  choices                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Choices = setmetatable({}, UIElement)
Choices.__index = Choices
Choices.name = "choices"

function Choices:init()
    self.height = self.ui.components.box.window_conf.height - 1

    self.ui.pagesize = math.floor(self.height / 2)

    self.window_conf = {
        relative = "win",
        win = self.ui.components.box.window.id,
        width = M.opts.window.width,
        height = self.height,
        row = 1,
        col = 0,
        style = "minimal",
        noautocmd = true,
    }
end

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
            return str .. string.rep(" ", M.opts.window.width - #vim.str_utf_pos(str))
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
--                                                                            --
--                                                                            --
--                                   cursor                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Cursor = setmetatable({}, UIElement)
Cursor.__index = Cursor
Cursor.name = "cursor"

function Cursor:init()
    self.index = 1
    self.buffer = self.ui.components.choices.buffer
end

function Cursor:update(delta)
    local elements = self.ui.components.choices.elements
    self.index = self.index + (delta or 0)
    self.index = math.min(self.index, #elements)
    self.index = math.max(self.index, 1)

    self:clear_highlights()

    if #elements > 0 then
        self:add_highlight("TelescopeSelection", self.index - 1, 0, -1)
    end
end

function Cursor:get()
    return self.ui.components.choices.elements[self.index]
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   input                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Input = setmetatable({}, UIElement)
Input.__index = Input
Input.name = 'input'

function Input:init()
    self.window_conf = {
        relative = "win",
        win = self.ui.components.prompt.window.id,
        width = M.opts.window.width - 2,
        height = 1,
        row = 0,
        col = 2,
        noautocmd = true,
        style = "minimal",
    }
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Popup                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Popup = {}
Popup.__index = Popup
Popup.UIComponents = List({
    Box,
    Choices,
    Cursor,
    Prompt,
    Input,
})

function Popup:new()
    local instance = setmetatable({}, self)

    instance.path = List()
    instance.source = {
        buffer = vim.api.nvim_get_current_buf(),
        window = vim.fn.win_getid(),
    }

    instance.components = Dict()
    instance.UIComponents:foreach(function(UIComponent)
        instance.components[UIComponent.name] = UIComponent:new(instance)
    end)

    instance:set_keymap()

    vim.cmd.startinsert()

    return instance
end

function Popup:get_actions()
    local actions = Dict()

    actions.close = function()
        self.components:values():mapm('close')
        vim.fn.win_gotoid(self.source.window)
    end

    actions.update = function()
        self.UIComponents:foreach(function(UIComponent)
            self.components[UIComponent.name]:update()
        end)
    end

    actions.clear_input = function()
	    vim.api.nvim_buf_set_lines(self.components.input.buffer, 0, 1, true, {""})
    end

    actions.cursor_down = function() self.components.cursor:update(1) end
    actions.cursor_up = function() self.components.cursor:update(-1) end

    actions.cursor_page_down = function() self.components.cursor:update(self.pagesize) end
    actions.cursor_page_up = function() self.components.cursor:update(-self.pagesize) end

    actions.insert_or_enter_selection = function()
        local element = self.components.cursor:get()

        if element.name == 'group' then
            self.path:append(tostring(element))
            actions.clear_input()
            actions.update()
        else
            actions.close()
            vim.api.nvim_input(element.string)
        end
    end

    actions.enter_parent = function()
        if #self.path > 0 then
            self.path:pop()
            actions.clear_input()
            actions.update()
        end
    end

    actions.enter_root = function()
        if #self.path > 0 then
            self.path = List()
            actions.clear_input()
            actions.update()
        end
    end

    return actions
end

function Popup:set_keymap()
    local actions = self:get_actions(state)

    Dict.foreach(M.opts.keymap, function(lhs, action)
        vim.keymap.set("i", lhs, actions[action], {silent = true, buffer = true})
    end)

	vim.api.nvim_create_autocmd(
        "TextChangedI",
        {
            callback = actions.update,
            buffer = self.components.input.buffer,
        }
    )

	vim.api.nvim_create_autocmd(
        "InsertLeave",
        {
            callback = actions.close,
            buffer = self.components.input.buffer,
            once = true,
        }
    )

	actions.update()
end

return function() Popup:new() end
