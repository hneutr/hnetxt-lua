local Popup = {}
Popup.__index = Popup
Popup.name = "popup"
Popup.width = 80

Popup.default_keymap = {
    ["<C-c>"] = "close",

    ["<C-n>"] = "cursor_down",
    ["<C-p>"] = "cursor_up",
    ["<Down>"] = "cursor_down",
    ["<Up>"] = "cursor_up",

    ["<C-f>"] = "cursor_page_down",
    ["<C-b>"] = "cursor_page_up",
}

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

    instance.namespace = vim.api.nvim_create_namespace(("htn.popup.%s.%s"):format(ui.name, instance.name))

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

function UIElement:init() return end

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
    local col = math.floor((n_cols - self.ui.width) / 2 - 1)

    self.window_conf = {
        relative = "editor",
        width = self.ui.width,
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
        width = self.ui.width,
        height = 1,
        row = -2,
        col = -1,
        border = {"╭", "─", "╮", "│", "┤", "─", "├", "│"},
        noautocmd = true,
        style = "minimal",
    }
end

function Prompt:title() return "" end

function Prompt:get_line() return "> " end

function Prompt:highlight_line() return end

function Prompt:update()
    self.window:update({title = self:title(), title_pos = "center"})

    self:clear_highlights()

	vim.api.nvim_buf_set_lines(self.buffer, 0, 1, true, {self:get_line()})

    self:highlight_line()
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
        width = self.ui.width,
        height = self.height,
        row = 1,
        col = 0,
        style = "minimal",
        noautocmd = true,
    }
end

function Choices:get_elements() return end

function Choices:format_element(element) return tostring(element) end

function Choices:highlight_element(element, line) return end

function Choices:set_lines()
	vim.api.nvim_buf_set_lines(
        self.buffer,
        0,
        -1,
        true,
        self.elements:map(function(e) return self:format_element(e) end)
    )
end

-- function Choices:update()
--     self.elements = self:get_elements()
--     self:clear_highlights()
-- end

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
    self.offset = 0
    self.buffer = self.ui.components.choices.buffer
end

function Cursor:update(delta)
    local elements = self.ui.components.choices.elements
    self.index = self.index + (delta or 0)
    self.index = math.min(self.index, #elements)
    self.index = math.max(self.index, 1)

    -- self:set_offset()

    self:clear_highlights()

    if #elements > 0 then
        self:add_highlight(self:get_hl_group(), self.index - 1 + self.offset, 0, -1)
    end
end

-- function Cursor:set_offset()
-- end
--
-- function Cursor:center()
-- end

function Cursor:get_hl_group() return "TelescopeSelection" end

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
        width = self.ui.width,
        height = 1,
        row = 0,
        col = 0,
        noautocmd = true,
        style = "minimal",
    }
end

function Input:update()
    local prompt_len = #self.ui.components.prompt:get_line()
    self.window:update({width = self.ui.width - prompt_len, col = prompt_len})
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Popup                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function Popup:new(args)
    local instance = setmetatable({}, self)

    instance.source = {
        buffer = vim.api.nvim_get_current_buf(),
        window = vim.fn.win_getid(),
        mode = vim.api.nvim_get_mode().mode,
    }

    instance:init(args or {})

    instance.ComponentClasses = List({
        instance.Box or Box,
        instance.Choices or Choices,
        instance.Cursor or Cursor,
        instance.Prompt or Prompt,
        instance.Input or Input,
    })

    instance.components = Dict()
    instance.ComponentClasses:foreach(function(ComponentClass)
        instance.components[ComponentClass.name] = ComponentClass:new(instance)
    end)

    instance:set_keymap()

    instance:update()

    vim.cmd.startinsert()

    return instance
end

function Popup:init(args) return end

function Popup:close()
    self.components:values():mapm('close')
    vim.fn.win_gotoid(self.source.window)

    if self.source.mode ~= 'i' then
        vim.api.nvim_input("<esc>")
    end
end

function Popup:update()
    self.ComponentClasses:foreach(function(ComponentClass)
        self.components[ComponentClass.name]:update()
    end)
end

function Popup:clear_input()
	vim.api.nvim_buf_set_lines(self.components.input.buffer, 0, 1, true, {""})
    self:update()
end

function Popup:cursor_down() self.components.cursor:update(1) end
function Popup:cursor_up() self.components.cursor:update(-1) end

function Popup:cursor_page_down() self.components.cursor:update(self.pagesize) end
function Popup:cursor_page_up() self.components.cursor:update(-self.pagesize) end

function Popup:get_action(key)
    self.actions = self.actions or {}
    self.actions[key] = self.actions[key] or function() self[key](self) end
    return self.actions[key]
end

function Popup:set_keymap()
    self.keymap = Dict(self.keymap):update(self.default_keymap)
    self.keymap:foreach(function(lhs, action)
        vim.keymap.set("i", lhs, self:get_action(action), {silent = true, buffer = true})
    end)

	vim.api.nvim_create_autocmd(
        "TextChangedI",
        {
            callback = self:get_action("update"),
            buffer = self.components.input.buffer,
        }
    )

	vim.api.nvim_create_autocmd(
        "InsertLeave",
        {
            callback = self:get_action("close"),
            buffer = self.components.input.buffer,
            once = true,
        }
    )
end

return {
    Popup = Popup,
    Box = Box,
    Choices = Choices,
    Cursor = Cursor,
    Prompt = Prompt,
    Input = Input,
}
