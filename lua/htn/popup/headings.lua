local ui = require("htn.ui")
local popup = require("htn.popup")
local Heading = require("htl.text.Heading")

local Popup = Class({
    name = "headings",
    data = {},
    keymap = {
        ["<CR>"]  = "goto_selection",
        ["<C-r>"] = "put_reference",

        ["<C-.>"] = "enter_selection",
        ["<C-,>"] = "enter_parent",
        ["<C-/>"] = "enter_root",

        ["<C-1>"] = "filter_h1",
        ["<C-2>"] = "filter_h2",
        ["<C-3>"] = "filter_h3",
        ["<C-4>"] = "filter_h4",
        ["<C-5>"] = "filter_h5",
        ["<C-6>"] = "filter_h6",

        ["<C-w>"] = "toggle_wordcounts",
        ["<C-l>"] = "toggle_lineage",

        ["<C-h>"] = "toggle_meta_filter_all",
        ["<C-j>"] = "toggle_meta_filter_create",
        ["<C-k>"] = "toggle_meta_filter_change",

        ["<M-h>"] = "toggle_meta_collapse_all",
        ["<M-j>"] = "toggle_meta_collapse_create",
        ["<M-k>"] = "toggle_meta_collapse_change",
    },
}, popup.Popup)


--------------------------------------------------------------------------------
--                                    Item                                    --
--------------------------------------------------------------------------------
local Item = Class({}, popup.Item)

function Item:init(args)
    local marker = args.marker
    local label = marker:next_sibling()
    local section = marker:parent():parent()

    self.level = tonumber(marker:type():match("atx_h(%d+)_marker"))
    self._level = Heading.levels[self.level]

    local range = {section:range(false)}
    self.range = {range[1], range[3]}
    self.line = range[1] + 1

    self.string, self.meta = Heading.Meta.parse(label and vim.treesitter.get_node_text(label, 0) or "")

    self.children = List()
    self.parents = self:get_parents(args.previous_item)
    self.include = self:get_inclusion()

    if self.include then
        self.parents:foreach(function(parent) parent.children:append(self) end)
    end
end

function Item:get_parents(previous_item)
    local parents = previous_item and previous_item.parents:clone():put(previous_item) or List()
    return parents:filter(function(parent) return parent.level < self.level end)
end

function Item:get_inclusion()
    local result = #self.string > 0
    result = result and not (self.string == "outline" and self.meta.hide)
    self.parents:foreach(function(parent) result = result and parent.include end)

    return result
end

function Item:cursor_highlight_group() return self._level.bg_hl_group end

function Item:highlight(line)
    self.ui.choices:add_highlight(self._level.hl_group, line, 0, -1)

    local texts = self:get_metas_for_display()

    if self.ui.show_wordcounts then
        texts:put({self:get_wordcount(), "Whitespace"})
    end

    texts:foreach(function(text) text[1] = text[1] .. " " end)

    if #texts > 0 then
        self.ui.choices:add_extmark(line, 0, {
            virt_text = texts:put({" ", "Text"}),
            virt_text_pos = "right_align",
            hl_mode = "combine",
        })
    end
end

function Item:set_nearest_displayed_parent()
    local displayed_parents = self.parents:filter(function(p) return p.display end)
    self.nearest_displayed_parent = #displayed_parents > 0 and displayed_parents[1] or nil
end

function Item:get_child_meta(children)
    local child_vals = Set.union(unpack(children:map(function(child) return child.meta.vals end)))
    return Heading.Meta(child_vals:vals())
end

function Item:get_metas_for_display()
    local child_signs = self:get_child_meta(self.children:filter(function(child)
        return child.nearest_displayed_parent == self and not child.display
    end)):get_signs(self.ui.meta.collapse)

    local signs = List()
    for i, sign in ipairs(self.meta:get_signs(self.ui.meta.collapse)) do
        local highlight = "Text"

        if sign == " " then
            sign = child_signs[i]
            highlight = "Whitespace"
        end

        signs:append({sign, highlight})
    end

    return signs
end

function Item:get_reference()
    return ("[%s][%s]"):format(
        self.string,
        ("#"):rep(self.level) .. " " .. self.string
    )
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
    return ("  "):rep(self.level - self.ui.choices.min_item_level) .. self.string
end

function Item:get_query()
    self.query = self.query or vim.treesitter.query.parse(
        "markdown",
        ("(atx_heading [%s] @hne_heading)"):format(
            Heading.levels:map(function(l) return l.selector end):join(" ")
        )
    )

    return self.query
end

function Item:filter()
    local result = true

    if not self.child_meta then
        self.child_meta = self:get_child_meta(self.children)
    end

    result = result and (not self.ui.parent or self.parents:contains(self.ui.parent))
    result = result and self.level <= self.ui.level
    result = result and (self.meta:filter(self.ui.meta.filter) or self.child_meta:filter(self.ui.meta.filter))
    result = result and self:fuzzy_match()

    self.display = result

    return result
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

    self.ui.parent = self.ui.parent or nil

    self.items = self.ui.items:filterm("filter")

    self.ui.items:mapm("set_nearest_displayed_parent")

    if self.ui.show_lineage then
        local seen_indexes = Set(self.items:map(function(item) return item.index end))
        self.items:foreach(function(item)
            item.parents:foreach(function(parent)
                if not seen_indexes:has(parent.index) then
                    self.items:append(parent)
                    seen_indexes:add_val(parent.index)
                end
            end)
        end)
        self.items:sort(function(a, b) return a.index < b.index end)
    end

    self.min_item_level = #self.items > 0 and math.min(unpack(self.items:col("level"))) or 0

    for i, item in ipairs(self.items) do
        if item.index <= last_cursor_index then
            self.ui.cursor.index = i
        end
    end

    -- move to the highest fuzzy score
    if self.ui.updated_by_input and self.ui.pattern then
        local score

        for i, item in ipairs(self.items) do
            if not score or item.score < score then
                score = item.score
                self.ui.cursor.index = i
            end
        end
    end

    -- move the cursor
    self.ui.cursor:move(0, true)
end

--------------------------------------------------------------------------------
--                                    Input                                   --
--------------------------------------------------------------------------------
local Input = Class({}, popup.Input)
Popup.Input = Input

function Input:highlight()
    local signs = Heading.Meta.get_displayable_signs(self.ui.meta)

    if #signs > 0 then
        self:add_extmark(0, 0, {
            virt_text = {{signs:join(" ") .. " ", "Text"}},
            virt_text_pos = "right_align",
            hl_mode = "combine",
        })
    end
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
function Popup:init(args)
    self.level = args.level or #Heading.levels
    -- TODO
    self.localize = args.localize
    self.parent = nil
    self.show_lineage = true
    self.show_wordcounts = false
    self.meta = Heading.Meta.get_display_defaults()

    if args.todo then
        self:toggle_meta("filter", "all")
    end

    self:set_items()
    self:set_height()
end

function Popup:set_height()
    local window_height = vim.api.nvim_win_get_config(self.source.window).height
    if #self.items * 2 > window_height then
        self.dimensions = {height = window_height}
    end
end

function Popup:title()
    if self.parent then
        return {{self.parent.string, self.parent._level.hl_group}}
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

function Popup:get_autocmds()
    return List({
        {
            event = "BufModifiedSet",
            opts = {
                buffer = self.source.buffer,
                callback = function() self:set_data("items", nil) end,
            }
        },
    })
end

function Popup:set_items()
    local items = self:get_data("items") or List()
    local excluded_ranges = self:get_data("excluded_ranges") or List()

    if #items > 0 then
        items:foreach(function(item) item.ui = self end)
    else
        local item
        for _, marker in Item:get_query():iter_captures(ui.ts.get_root(), 0, 0, -1) do
            item = Item:new(self, {marker = marker, previous_item = item})

            if item.include then
                items:append(item)
                item.index = #items
            else
                excluded_ranges:append(items.range)
            end
        end

        self:set_data("items", items)
        self:set_data("excluded_ranges", excluded_ranges)
    end

    self.excluded_ranges = excluded_ranges
    self.items = items
end

-----------------------------------[ actions ]----------------------------------
function Popup:define_actions()
    for level = 1, #Heading.levels do
        self.actions[("filter_h%d"):format(level)] = function()
            self.level = self.level ~= level and level or #Heading.levels
            self:update()
        end
    end

    List({"filter", "collapse"}):foreach(function(action)
        List({"all", "create", "change"}):foreach(function(group)
            self.actions[("toggle_meta_%s_%s"):format(action, group)] = function()
                self:toggle_meta(action, group)
                self:update()
            end
        end)
    end)
end

function Popup:toggle_meta(field, group)
    if group == 'all' then
        if #self.meta[field]:vals() == 0 then
            self.meta[field] = Set(Heading.Meta.conf.display_groups)
        else
            self.meta[field] = Set()
        end
    else
        if self.meta[field]:has(group) then
            self.meta[field]:remove(group)
        else
            self.meta[field]:add(group)
        end
    end
end

function Popup:open()
    self.prompt:update()
    self.input:update()
    self.choices:update()

    for i, item in ipairs(self.choices.items) do
        self.cursor.index = item.line <= self.source.line and i or self.cursor.index
    end

    self.cursor:move(0, true)

    if self.localize then
        local parents = self.cursor:get().parents
        if #parents > 0 then
            self.parent = parents[#parents]
            self:update()
        end
    end
end

function Popup:goto_selection()
    self:close()
    ui.set_cursor({row = self.cursor:get().line})
end

function Popup:enter_selection()
    self.parent = self.cursor:get()

    -- when entering a parent of the filter level, increment it by 1
    if self.level == self.parent.level then
        self.level = self.level + 1
    end

    -- clear text on enter bc usually it was used to find the entered item
    vim.api.nvim_input("<C-u>")

    self.cursor.index = 1

    self:update()
end

function Popup:enter_parent()
    if self.parent then
        local parents = self.parent.parents
        self.parent = #parents > 0 and parents[1]
        self:update()
    end
end

function Popup:enter_root()
    self.parent = nil
    self:update()
end

function Popup:toggle_lineage()
    self.show_lineage = not self.show_lineage
    self:update()
end

function Popup:put_reference()
    local reference = self.cursor:get():get_reference()

    self:close()

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    local line = vim.api.nvim_get_current_line()
    local before = line:sub(1, col + 1)
    local after = line:sub(col + 2)

    vim.api.nvim_set_current_line(before .. reference .. after)
    vim.api.nvim_win_set_cursor(0, {row, col + 1 + #reference})
end

function Popup:toggle_wordcounts()
    self.show_wordcounts = not self.show_wordcounts

    if self.show_wordcounts then
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
