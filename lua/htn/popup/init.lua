local ui = require("htn.ui")

local Popup = Class({
    name = "popup",
    width = 80,
    height = 41,
    default_keymap = {
        ["<C-c>"] = "close",

        ["<C-n>"] = "cursor_down",
        ["<C-p>"] = "cursor_up",
        ["<Down>"] = "cursor_down",
        ["<Up>"] = "cursor_up",

        ["<C-f>"] = "cursor_page_down",
        ["<C-b>"] = "cursor_page_up",

        ["<C-z>"] = "center_cursor",
    }
})

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Window                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Window = Class()

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
local Component = Class({name = "component"})

function Component:new(ui)
    local instance = setmetatable({ui = ui}, self)

    ui[instance.name] = instance

    instance.namespace = vim.api.nvim_create_namespace(("htn.popup.%s.%s"):format(ui.name, instance.name))

    instance:init()

    if instance.window_conf then
        instance.buffer = vim.api.nvim_create_buf(false, true)
        instance.window = Window:new(instance.buffer, instance.window_conf)
    end

    return instance
end

function Component:close()
    return self.window and self.window:close()
end

function Component:reset()
	vim.api.nvim_buf_clear_namespace(self.buffer, self.namespace, 0, -1)
end

function Component:set_lines(lines)
    self:reset()
	vim.api.nvim_buf_set_lines(self.buffer, 0, -1, true, lines)
end

function Component:add_highlight(group, line, start_col, end_col)
    vim.api.nvim_buf_add_highlight(self.buffer, self.namespace, group, line, start_col, end_col)
end

function Component:add_extmark(line, col, opts)
    vim.api.nvim_buf_set_extmark(self.buffer, self.namespace, line, col, opts)
end

function Component:init() return end
function Component:update() return end
function Component:highlight() return end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Prompt                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Prompt = Class({name = "prompt"}, Component)

function Prompt:init()
    self.window_conf = {
        relative = "win",
        win = self.ui.choices.window.id,
        width = self.ui.dimensions.width,
        height = 1,
        row = -3,
        col = -1,
        border = {"╭", "─", "╮", "│", "┤", "─", "├", "│"},
        noautocmd = true,
        style = "minimal",
    }
end

function Prompt:get() return "> " end

function Prompt:update()
    self.window:update({title = (" %s "):format(self.ui:title() or self.ui.name), title_pos = "center"})

    self:set_lines({self:get()})
    self:highlight()
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    Item                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Item = {}
Item.__index = Item

function Item:new(ui, args)
    local instance = setmetatable({ui = ui}, self)

    instance:init(args)

    return instance
end

function Item:init(str)
    self.string = str
end

function Item:choice_string() return self.string end
function Item:fuzzy_string() return self.string end

function Item:tostring()
    local str = self:choice_string()
    return str .. string.rep(" ", self.ui.dimensions.width - #vim.str_utf_pos(str))
end

function Item:filter() return self:fuzzy_match() end

function Item:fuzzy_match()
    return not self.ui.pattern or MiniFuzzy.match(self.ui.pattern, self:fuzzy_string()).score > 0
end

function Item:cursor_highlight_group() return "TelescopeSelection" end

function Item:highlight_cursor(line)
    self.ui.cursor:add_highlight(self:cursor_highlight_group(), line, 0, -1)
end

function Item:highlight(line) return end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Choices                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Choices = Class({name = "choices"}, Component)

function Choices:init()
    self.window_conf = {
        relative = "editor",
        width = self.ui.dimensions.width,
        height = self.ui.dimensions.height,
        row = self.ui.dimensions.row,
        col = self.ui.dimensions.col,
        style = "minimal",
        noautocmd = true,
        border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"},
    }
end

function Choices:get_items() return List() end

function Choices:visible_range()
    local start = self.ui.cursor.offset + 1
    local stop = start + self.ui.dimensions.height - 1
    return start, stop
end

function Choices:update()
    self.items = self:get_items()
    self:draw()
end

function Choices:draw()
    local to_draw = self.items:slice(self:visible_range())

    self:set_lines(to_draw:mapm("tostring"))

    for i, item in ipairs(to_draw) do
        item:highlight(i - 1)
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Cursor                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Cursor = Class({name = "cursor"}, Component)

function Cursor:init()
    self.index = 1
    self.offset = 0
    self.buffer = self.ui.choices.buffer
end

function Cursor:get()
    return self.ui.choices.items[self.index]
end

function Cursor:update()
    self:bound_index()
    self.offset = 0
    self:draw()
end

function Cursor:draw()
    self:reset()

    if #self.ui.choices.items > 0 then
        self:add_highlight(
            self:get():cursor_highlight_group(),
            self.index - 1 - self.offset,
            0,
            -1
        )
    end
end

function Cursor:move(delta, center)
    self:bound_index(delta)

    local start_index, stop_index = self.ui.choices:visible_range()

    if self.index < start_index then
        self.offset = self.index - 1
    elseif stop_index < self.index then
        self.offset = self.index - self.ui.dimensions.height
    end

    if center then
        self.offset = self.index - self.ui.dimensions.half_page - 1
    end

    self:bound_offset()

    self.ui.choices:draw()
    self:draw()
end

function Cursor:bound_index(delta)
    self.index = math.between(self.index + (delta or 0), {min = 1, max = #self.ui.choices.items})
end

function Cursor:bound_offset()
    self.offset = math.between(self.offset, {min = 0, max = #self.ui.choices.items - self.ui.dimensions.height})
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Input                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Input = Class({name = 'input'}, Component)

function Input:init()
    self.window_conf = {
        relative = "win",
        win = self.ui.prompt.window.id,
        width = self.ui.dimensions.width,
        height = 1,
        row = 0,
        col = 0,
        noautocmd = true,
        style = "minimal",
    }
end

function Input:update()
    local prompt_len = #vim.str_utf_pos(self.ui.prompt:get())
    self.window:update({width = self.ui.dimensions.width - prompt_len, col = prompt_len})
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

    instance:set_dimensions()
    instance:init(args or {})

    instance.components = List({
        instance.Choices or Choices,
        instance.Cursor or Cursor,
        instance.Prompt or Prompt,
        instance.Input or Input,
    }):mapm("new", instance)

    instance:set_keymap()

    instance:update()

    vim.cmd.startinsert()

    return instance
end

function Popup:set_dimensions()
    self.dimensions = {
        height = self.height,
        width = self.width,
    }

    self.dimensions.row = math.floor((vim.go.lines - self.height) / 2)
    self.dimensions.col = math.floor((vim.go.columns - self.width) / 2 - 1)
    self.dimensions.half_page = math.floor(self.dimensions.height / 2)
end

function Popup:init(args) return end

function Popup:title() return self.name end

function Popup:close()
    self.components:mapm("close")

    vim.fn.win_gotoid(self.source.window)

    if self.source.mode ~= 'i' then
        vim.api.nvim_input("<esc>")
    end
end

function Popup:update()
    self.pattern = ui.get_cursor_line()
    self.pattern = #self.pattern > 0 and self.pattern or nil
    self.components:mapm("update")
end

function Popup:cursor_down() self.cursor:move(1) end
function Popup:cursor_up() self.cursor:move(-1) end

function Popup:cursor_page_down() self.cursor:move(self.dimensions.half_page, true) end
function Popup:cursor_page_up() self.cursor:move(-self.dimensions.half_page, true) end

function Popup:center_cursor() self.cursor:move(0, true) end

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
            buffer = self.input.buffer,
        }
    )

	vim.api.nvim_create_autocmd(
        "InsertLeave",
        {
            callback = self:get_action("close"),
            buffer = self.input.buffer,
            once = true,
        }
    )
end

return {
    Popup = Popup,
    Item = Item,
    Choices = Choices,
    Cursor = Cursor,
    Prompt = Prompt,
    Input = Input,
}
