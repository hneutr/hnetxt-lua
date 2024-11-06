local ui = require("htn.ui")
local popup = require("htn.popup")

local Heading = require("htl.text.Heading")

local Popup = setmetatable({}, popup.Popup)
Popup.__index = Popup
Popup.name = "headings"
Popup.keymap = {
    ["<C-,>"] = "close",
    ["<C-.>"] = "close",

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

    ["<C-t>"] = "filter_todo",
    ["<C-w>"] = "filter_write",
    ["<C-a>"] = "filter_change",
    ["<C-e>"] = "filter_finish",
    ["<C-m>"] = "filter_move",
    ["<C-o>"] = "filter_outline",
}

Popup.data = Dict()

--------------------------------------------------------------------------------
--                                    Item                                    --
--------------------------------------------------------------------------------
local Item = setmetatable({}, popup.Item)
Item.__index = Item

function Item:init(marker_node)
    local content_node = marker_node:next_sibling()

    self.string = content_node and vim.treesitter.get_node_text(content_node, 0) or ""
    self.line = marker_node:start() + 1
    self.level = tonumber(marker_node:type():match("atx_h(%d+)_marker"))
    self._level = Heading.levels[self.level]
    self.string, self.meta = Heading.parse(self.string)

    self.n_children = 0

    self.pad_level_start = 0
end

function Item:include()
    local result = true
    result = result and #self.string > 0

    self.meta:foreach(function(m_conf)
        if m_conf.key == "outline" and self.string == "outline" then
            result = false
        end
    end)

    return result
end

function Item:set_context(items, level_to_parent)
    self.index = #items
    self.parents = level_to_parent:slice(1, self.level):unique()

    self.parents:foreach(function(parent_i)
        if parent_i > 0 then
            items[parent_i].n_children = items[parent_i].n_children + 1
        end
    end)

    for i = self.level + 1, #Heading.levels do
        level_to_parent[i] = self.index
    end
end

function Item:cursor_highlight_group() return self._level.bg_hl_group end

function Item:highlight(line)
    self.ui.components.choices:add_highlight(self._level.hl_group, line, 0, -1)

    local text = self.meta:col('symbol'):join(" ")

    if #text > 0 then
        self.ui.components.choices:add_extmark(
            line,
            0,
            {
                virt_text = {{text .. " ", "Text"}},
                virt_text_pos = "right_align",
                hl_mode = "combine",
            }
        )
    end
end

function Item:choice_string()
    return ("  "):rep(self.level - self.pad_level_start) .. self.string
end

function Item:get_query()
    self.query = self.query or vim.treesitter.query.parse(
        "markdown",
        string.format(
            "(atx_heading [%s] @hne_heading)",
            Heading.levels:map(function(l) return l.selector end):join(" ")
        )
    )

    return self.query
end

function Item:filter()
    local result = true

    result = result and self.parents:contains(self.ui.parent)
    result = result and self.level <= self.ui.level

    if self.ui.todo then
        local is_todo = false
        self.meta:foreach(function(meta) is_todo = is_todo or meta.todo end)
        result = result and is_todo
    end

    if self.ui.meta_type then
        local is_type = false
        self.meta:foreach(function(meta) is_type = is_type or meta.key == self.ui.meta_type end)
        result = result and is_type
    end

    return result
end

--------------------------------------------------------------------------------
--                                   Prompt                                   --
--------------------------------------------------------------------------------
local Prompt = setmetatable({}, popup.Prompt)
Prompt.__index = Prompt

Popup.Prompt = Prompt

function Prompt:title()
    return string.format(
        " %s ",
        self.ui.parent and self.ui.parent ~= 0 and self.ui.items[self.ui.parent].string or "headings"
    )
end

function Prompt:get_line()
    local parts = List()

    if self.ui.todo then
        parts:append("todo")
    end

    if self.ui.meta_type then
        parts:append(Heading.conf.meta[self.ui.meta_type].symbol)
    end

    if self.ui.level < #Heading.levels then
        parts:append(self.ui.level)
    end

    if #parts > 0 then
        self.filters_string = parts:map(tostring):join(" ")
        return ("[%s] > "):format(self.filters_string)
    end

    return "> "
end

function Prompt:highlight()
    if self.ui.level < #Heading.levels then
        self:add_highlight(
            Heading.levels[self.ui.level].hl_group,
            0,
            #self.filters_string,
            #self.filters_string + 1
        )
    end
end

--------------------------------------------------------------------------------
--                                   Choices                                  --
--------------------------------------------------------------------------------
local Choices = setmetatable({}, popup.Choices)
Choices.__index = Choices

Popup.Choices = Choices

function Choices:get_items()
    if self.ui.nearest then
        local line = self.ui.nearest
        self.ui.nearest = false
        self.ui.items:foreach(function(item)
            self.ui.parent = item.line <= line and item.index or self.ui.parent
        end)
    end

    self.ui.parent = self.ui.parent or 0

    local items = self.ui.items:filter(function(item) return item:filter() end)
    --     return item.parents:contains(self.ui.parent) and item.level <= self.ui.level
    -- end)

    items = self:fuzzy_filter(items)

    if #items > 0 then
        local pad_level_start = math.min(unpack(items:col("level")))
        items:foreach(function(item) item.pad_level_start = pad_level_start end)
    end

    return items
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
function Popup:init(args)
    self.level = args.level or #Heading.levels
    self.parent = 0
    self.nearest = args.nearest and ui.get_cursor().row

    self:watch()
    self:set_items()

    self.actions = {}
    for level = 1, #Heading.levels do
        self.actions[string.format("filter_h%d", level)] = function()
            self.level = self.level ~= level and level or #Heading.levels
            self:update()
        end
    end

    for key, conf in pairs(Heading.conf.meta) do
        self.actions[string.format("filter_%s", key)] = function()
            self.todo = false
            self.meta_type = self.meta_type ~= key and key or nil
            self:update()
        end
    end
end

function Popup:get_data(field)
    local key = tostring(self.source.buffer)
    self.data[key] = self.data[key] or {}
    return self.data[key][field]
end

function Popup:set_data(field, val)
    local key = tostring(self.source.buffer)
    self.data[key][field] = val
end

function Popup:watch()
    if self:get_data("watch_autocmd") then
        return
    end

    self:set_data(
        "watch_autocmd",
        vim.api.nvim_create_autocmd(
            "BufModifiedSet",
            {
                buffer = self.source.buffer,
                callback = function() self:set_data("items", nil) end,
            }
        )
    )
end

function Popup:set_items()
    local items = self:get_data("items")

    if items then
        items:foreach(function(item) item.ui = self end)
    else
        local level_to_parent = List({0, 0, 0, 0, 0, 0})

        items = List()
        for _, node in Item:get_query():iter_captures(ui.ts.get_root(), 0, 0, -1) do
            local item = Item:new(self, node)
            if item:include() then
                items:append(item)
                item:set_context(items, level_to_parent)
            end
        end

        self:set_data("items", items)
    end

    self.items = items
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
        local parents = self.items[self.parent].parents
        self.parent = parents[#parents]
        self:update()
    end
end

function Popup:enter_root()
    self.parent = 0
    self:update()
end

function Popup:filter_todo()
    self.todo = self.todo or false
    self.todo = not self.todo
    self.meta_type = nil
    self:update()
end

return function(args) return function() Popup:new(args) end end
