local ui = require("htn.ui")
local popup = require("htn.popup")

local Heading = require("htl.text.Heading")

local Popup = Class({
    name = "headings",
    data = {},
    keymap = {
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
        ["<C-r>"] = "put_reference",
        ["<M-p>"] = "filter_parents",
    },
}, popup.Popup)

--------------------------------------------------------------------------------
--                                    Item                                    --
--------------------------------------------------------------------------------
local Item = Class({}, popup.Item)

function Item:init(marker_node)
    local content_node = marker_node:next_sibling()

    self.string = content_node and vim.treesitter.get_node_text(content_node, 0) or ""
    self.line = marker_node:start() + 1
    self.level = tonumber(marker_node:type():match("atx_h(%d+)_marker"))
    self._level = Heading.levels[self.level]
    self.string, self.meta = Heading.parse(self.string)

    self.children = List()

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
            items[parent_i].children:append(self)
        end
    end)

    for i = self.level + 1, #Heading.levels do
        level_to_parent[i] = self.index
    end
end

function Item:cursor_highlight_group() return self._level.bg_hl_group end

function Item:highlight(line)
    self.ui.choices:add_highlight(self._level.hl_group, line, 0, -1)

    local text = self.meta:col('symbol'):join(" ")

    if #text > 0 then
        self.ui.choices:add_extmark(
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

    if #self.ui.meta_types:keys() > 0 then
        result = result and self.meta:map(function(m)
            return self.ui.meta_types[m.key]
        end):any()
    end

    return result and self:fuzzy_match()
end

--------------------------------------------------------------------------------
--                                   Prompt                                   --
--------------------------------------------------------------------------------
local Prompt = Class({}, popup.Prompt)

Popup.Prompt = Prompt

function Prompt:get()
    local parts = List()

    if self.ui.meta_types then
        parts:extend(self.ui.meta_types:keys():sorted():map(function(key)
            return Heading.conf.meta[key].symbol
        end))
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
local Choices = Class({}, popup.Choices)

Popup.Choices = Choices

function Choices:update()
    local last_cursor_index = self.items and self.items[self.ui.cursor.index].index or -1

    self.ui.parent = self.ui.parent or 0

    self.items = self.ui.items:filterm("filter")

    if self.ui.include_parents then
        local seen_indexes = Set(self.items:map(function(item) return item.index end))
        self.items:foreach(function(item)
            item.parents:foreach(function(index)
                if not seen_indexes:has(index) then
                    self.items:append(self.ui.items[index])
                    seen_indexes:add_val(index)
                end
            end)
        end)
        self.items:sort(function(a, b) return a.index < b.index end)
    end

    if #self.items > 0 then
        local pad_level_start = math.min(unpack(self.items:col("level")))
        self.items:foreach(function(item) item.pad_level_start = pad_level_start end)
    end

    for i, item in ipairs(self.items) do
        if item.index == last_cursor_index then
            self.ui.cursor.index = i
            self.ui.cursor:move(0, true)
            return
        end
    end
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
function Popup:init(args)
    self.level = args.level or #Heading.levels
    self.meta_types = Dict({})
    self.parent = 0
    self.include_parents = true

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
            self.meta_types[key] = not self.meta_types[key] and true or nil
            self:update()
        end
    end
end

function Popup:get_data(field)
    local key = self.source.buffer
    self.data[key] = self.data[key] or {}
    return self.data[key][field]
end

function Popup:set_data(field, val)
    self.data[self.source.buffer][field] = val
end

function Popup:watch()
    return self:get_data("watch_autocmd") or self:set_data(
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

function Popup:title()
    if self.parent ~= 0 then
        local item = self.items[self.parent]
        return {{item.string, item._level.hl_group}}
    end
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

function Popup:open()
    self.prompt:update()
    self.input:update()
    self.choices:update()

    for i, item in ipairs(self.choices.items) do
        self.cursor.index = item.line <= self.source.line and i or self.cursor.index
    end

    self.cursor:move(0, true)
end

function Popup:goto_selection()
    self:close()
    ui.set_cursor({row = self.cursor:get().line})
end

function Popup:enter_selection()
    self.parent = self.cursor:get().index
    self.cursor.index = 1
    self:update()
end

function Popup:enter_parent()
    if self.parent ~= 0 then
        local parents = self.items[self.parent].parents
        self.parent = parents[#parents]
        self:update()
    end
end

function Popup:enter_root()
    self.parent = 0
    self:update()
end

function Popup:filter_parents()
    self.include_parents = not self.include_parents
    self:update()
end

function Popup:filter_todo()
    if #self.meta_types:keys() > 0 then
        self.meta_types = Dict()
    else
        Heading.conf.meta:foreach(function(key, meta)
            self.meta_types[key] = meta.todo
        end)
    end
    self:update()
end

function Popup:put_reference()
    local item = self.cursor:get()
    local reference = ("[%s][%s]"):format(item.string, ("#"):rep(item.level) .. " " .. item.string)

    self:close()

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    local line = vim.api.nvim_get_current_line()
    local before = line:sub(1, col + 1)
    local after = line:sub(col + 2)

    vim.api.nvim_set_current_line(before .. reference .. after)
    vim.api.nvim_win_set_cursor(0, {row, col + 1 + #reference})
end

return function(args) return function() Popup:new(args) end end
