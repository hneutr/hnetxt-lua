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

        ["<M-1>"] = "filter_m1",
        ["<M-2>"] = "filter_m2",
        ["<M-3>"] = "filter_m3",
        ["<M-4>"] = "filter_m4",
        ["<M-5>"] = "filter_m5",
        ["<M-6>"] = "filter_m6",
        ["<M-7>"] = "filter_m7",
        ["<M-8>"] = "filter_m8",
        ["<M-9>"] = "filter_m9",
        ["<M-0>"] = "filter_todo",

        ["<C-r>"] = "put_reference",
        ["<M-p>"] = "filter_parents",
        ["<C-w>"] = "toggle_wordcounts",
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

    -- TODO: wordcount stuff
    self.range = {}
    self.range[1], _, self.range[2] = marker_node:parent():parent():range(false)

    self.level = tonumber(marker_node:type():match("atx_h(%d+)_marker"))
    self._level = Heading.levels[self.level]
    self.string, self.meta = Heading.parse(self.string)

    self.children = List()

    self.pad_level_start = 0
end

function Item:include()
    local result = true
    result = result and #self.string > 0

    self.meta:foreach(function(key)
        if key == "outline" and self.string == "outline" then
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

function Item:set_child_meta()
    self.child_meta = Set()
    self.children:foreach(function(child) self.child_meta:add(child.meta) end)
end

function Item:cursor_highlight_group() return self._level.bg_hl_group end

function Item:highlight(line)
    self.ui.choices:add_highlight(self._level.hl_group, line, 0, -1)

    local texts = Heading.conf.meta:filter(function(conf)
        return conf.symbol
    end):map(function(conf)
        if self.meta:has(conf.key) then
            return {conf.symbol .. " ", "Text"}
        elseif self.child_meta:has(conf.key) then
            return {conf.symbol .. " ", "Whitespace"}
        end

        return {"  ", "Text"}
    end)

    if self.ui.display_wordcounts then
        texts:put({self:get_wordcount() .. " ", "Whitespace"})
    end

    if #texts > 0 then
        self.ui.choices:add_extmark(line, 0, {
            virt_text = texts:put({" ", "Text"}),
            virt_text_pos = "right_align",
            hl_mode = "combine",
        })
    end
end

function Item:get_wordcount()
    if self.wordcount == 0 then
        return ""
    end

    local s = "<.1"
    if self.wordcount >= 100 then
        s = tostring(math.floor((self.wordcount / 100) + .5) / 10)
    end

    return s .. "k"
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

    if #self.ui.metas:keys() > 0 then
        result = result and self.meta:vals():map(function(key)
            return self.ui.metas[key]
        end):any()
    end

    return result and self:fuzzy_match()
end

--------------------------------------------------------------------------------
--                                   Prompt                                   --
--------------------------------------------------------------------------------
local Prompt = Class({}, popup.Prompt)
Popup.Prompt = Prompt

function Prompt:highlight()
    if self.ui.level < #Heading.levels then
        self:add_highlight(Heading.levels[self.ui.level].hl_group, 0, 0, 1)
    end
end

--------------------------------------------------------------------------------
--                                   Choices                                  --
--------------------------------------------------------------------------------
local Choices = Class({}, popup.Choices)

Popup.Choices = Choices

function Choices:update()
    local last_cursor_index = -1
    if self.items and #self.items >= self.ui.cursor.index then
        last_cursor_index = self.items[self.ui.cursor.index].index
    end

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
        end
    end

    self.ui.cursor:move(0, true)
end

--------------------------------------------------------------------------------
--                                    Input                                   --
--------------------------------------------------------------------------------
local Input = Class({}, popup.Input)
Popup.Input = Input

function Input:highlight()
    if self.ui.metas then
        local text = Heading.conf.meta:filter(function(conf)
            return conf.symbol
        end):map(function(conf)
            return self.ui.metas[conf.key] and conf.symbol or " "
        end):join(" ")

        self:add_extmark(
            0,
            0,
            {
                virt_text = {{text .. " ", "Text"}},
                virt_text_pos = "right_align",
                hl_mode = "combine",
            }
        )
    end
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
function Popup:init(args)
    self.level = args.level or #Heading.levels
    self.metas = Dict()
    self.parent = 0
    self.include_parents = true
    self.display_wordcounts = false

    self:watch()
    self:set_items()

    self.actions = {}
    for level = 1, #Heading.levels do
        self.actions[string.format("filter_h%d", level)] = function()
            self.level = self.level ~= level and level or #Heading.levels
            self:update()
        end
    end

    for _, conf in ipairs(Heading.conf.meta) do
        self.actions[string.format("filter_%s", conf.key)] = function()
            self.metas[conf.key] = not self.metas[conf.key] and true or nil
            self:update()
        end
    end

    for i, conf in ipairs(Heading.conf.meta) do
        self.actions[("filter_m%d"):format(i)] = function()
            self.metas[conf.key] = not self.metas[conf.key] and true or nil
            self:update()
        end
    end

    if args.todo then
        self:toggle_todos()
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
    local excluded_ranges = self:get_data("excluded_ranges")

    if items then
        items:foreach(function(item) item.ui = self end)
    else
        excluded_ranges = List()

        local level_to_parent = List({0, 0, 0, 0, 0, 0})

        items = List()
        for _, node in Item:get_query():iter_captures(ui.ts.get_root(), 0, 0, -1) do
            local item = Item:new(self, node)
            if item:include() then
                items:append(item)
                item:set_context(items, level_to_parent)
            else
                excluded_ranges:append(item.range)
            end
        end

        self:set_data("excluded_ranges", excluded_ranges)
        self:set_data("items", items)
        items:foreachm("set_child_meta")
    end

    self.excluded_ranges = excluded_ranges
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

function Popup:toggle_todos()
    if #self.metas:keys() > 0 then
        self.metas = Dict()
    else
        Heading.conf.meta:foreach(function(conf)
            self.metas[conf.key] = conf.todo
        end)
    end
end

function Popup:goto_selection()
    self:close()
    ui.set_cursor({row = self.cursor:get().line})
end

function Popup:enter_selection()
    self.parent = self.cursor:get().index
    self.cursor.index = 1

    -- when entering a parent of the filter level, increment it by 1
    if self.level == self.items[self.parent].level then
        self.level = self.level + 1
    end

    -- clear text on enter bc usually it was used to find the entered item
    vim.api.nvim_input("<C-u>")

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
    self:toggle_todos()
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

function Popup:toggle_wordcounts()
    self.display_wordcounts = not self.display_wordcounts

    if self.display_wordcounts then
        local line_wordcounts = List(vim.api.nvim_buf_get_lines(self.source.buffer, 0, -1, true)):map(function(l)
            return #l:split(" ")
        end)

        self.excluded_ranges:foreach(function(range)
            for i = range[1] + 1, range[2] do
                line_wordcounts[i] = 0
            end
        end)

        self.total_words = 0
        self.items:foreach(function(item)
            item.wordcount = 0
            for i = item.range[1] + 1, item.range[2] do
                item.wordcount = item.wordcount + line_wordcounts[i]
            end
            self.total_words = self.total_words + item.wordcount
        end)
    end

    self:update()
end

return function(args) return function() Popup:new(args) end end
