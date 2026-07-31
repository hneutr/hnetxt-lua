local ui_utils = require("htn.ui")
local popup = require("htn.popup")
local Heading = require("htl.text.Heading")

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
    self.cursor_highlight_group = self._level.bg_hl_group

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
    return parents:filter(parent -> parent.level < self.level)
end

function Item:get_inclusion()
    local result = #self.string > 0
    result = result and not (self.string == "outline" and self.meta.hide)
    self.parents:foreach(function(parent) result = result and parent.include end)

    return result
end

function Item:highlight(line)
    self.ui.choices:add_highlight(self._level.hl_group, line, 0, -1)

    local texts = self:get_metas_for_display()

    if self.ui.show_wordcounts then
        texts:put({self.get_wordcount(self.wordcount), "Whitespace"})
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
    local displayed = self.parents:filter(p -> p.display)
    self.nearest_displayed_parent = #displayed > 0 and displayed[1] or nil
end

function Item:get_child_meta(children)
    local child_vals = Set.union(unpack(children:map(child -> child.meta.vals)))
    return Heading.Meta(child_vals:vals())
end

function Item:get_metas_for_display()
    local child_signs = self:get_child_meta(self.children:filter(function(child)
        return not child.display and child.nearest_displayed_parent == self
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

function Item.get_wordcount(wordcount)
    if wordcount == 0 then
        return ""
    end

    local s = "<.1"
    if wordcount >= 100 then
        s = tostring(math.floor((wordcount / 100) + .5) / 10)
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
            Heading.levels:map(l -> l.selector):join(" ")
        )
    )

    return self.query
end

function Item:filter()
    if not self.child_meta then
        self.child_meta = self:get_child_meta(self.children)
    end

    local result = true

    result = result and (not self.ui.parent or self.parents:contains(self.ui.parent))
    result = result and self.level <= self.ui.level
    result = result and self:fuzzy_match()

    -- this is sort of weird in that it includes both:
    -- - children w/ matching metadata (as it should)
    -- - parents w/o matching meta (as it maybe shouldn't?)
    -- ... but that's kind of an edge case so I guess it's fine?
    result = result and (self.meta:filter(self.ui.meta.filter) or self.child_meta:filter(self.ui.meta.filter))

    self.display = result

    return result
end

--------------------------------------------------------------------------------
--                                   Prompt                                   --
--------------------------------------------------------------------------------
local Prompt = Class({}, popup.Prompt)

function Prompt:highlight()
    if self.ui.level < #Heading.levels then
        self:add_highlight(Heading.levels[self.ui.level].hl_group, 0, 0, 1)
    end
end

--------------------------------------------------------------------------------
--                                   Choices                                  --
--------------------------------------------------------------------------------
local Choices = Class({}, popup.Choices)

function Choices:get_item_nearest_source_cursor(items)
    local nearest_item, index
    for i, item in ipairs(items or self.ui.items) do
        if item.line <= self.ui.source.line then
            nearest_item = item
            index = i
        end
    end

    return nearest_item, index or 0
end

function Choices:localize()
    local item = self:get_item_nearest_source_cursor()

    if item then
        self.ui.parent = item.parents:clone():put(item):pop()
    end
end

function Choices:update()
    if self.ui.update_trigger == 'open' and self.ui.localize then
        self:localize()
    end

    self.ui.items:foreach(function(item)
        item:filter()

        if self.ui.show_lineage and item.display then
            item.parents:foreach(function(p) p.display = true end)
        end

        item:set_nearest_displayed_parent()
    end)

    self.items = self.ui.items:filter(item -> item.display)

    self.min_item_level = #self.items > 0 and math.min(unpack(self.items:col("level"))) or 0

    -- move the cursor to the item visible and nearest the source buffer's cursor
    if self.ui.update_trigger == 'open' then
        local _, index = self:get_item_nearest_source_cursor(self.items)
        self.ui.cursor.index = index
    -- move the cursor to the highest fuzzy match
    elseif self.ui.update_trigger == "input" and self.ui.pattern then
        local score
        for i, item in ipairs(self.items) do
            if item.score > 0 and (not score or item.score < score) then
                score = item.score
                self.ui.cursor.index = i
            end
        end
    -- move the cursor upwards to its previous item
    elseif self.ui.cursor.item then
        for i, item in ipairs(self.items) do
            if item.index <= self.ui.cursor.item.index then
                self.ui.cursor.index = i
            end
        end
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Cursor                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Cursor = Class({}, popup.Cursor)

function Cursor:update()
    self:move(0, self.ui.update_trigger == "open")
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    Input                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Input = Class({}, popup.Input)

function Input:highlight()
    local signs = Heading.Meta.get_displayable_signs(self.ui.meta):map(sign -> {sign .. " ", "Text"})

    if self.ui.show_wordcounts then
        -- sum displayed items
        local wordcount = self.ui.choices.items:map(function(item)
            return item.nearest_displayed_parent == nil and item.wordcount or 0
        end):reduce('+')

        signs:put({Item.get_wordcount(wordcount) .. " ", "Whitespace"})
    end

    if #signs > 0 then
        self:add_extmark(0, 0, {
            virt_text = signs,
            virt_text_pos = "right_align",
            hl_mode = "combine",
        })
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    Popup                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Popup = Class({
    name = "headings",
    data = {},
    Prompt = Prompt,
    Cursor = Cursor,
    Choices = Choices,
    Input = Input,
}, popup.Popup)

function Popup:init(args)
    self.level = args.level or #Heading.levels
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
                callback = function()
                    self:set_data("items", nil)
                    self:set_data("excluded_ranges", nil)
                end,
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
        for _, marker in Item:get_query():iter_captures(ui_utils.ts.get_root(), 0, 0, -1) do
            item = Item:new(self, {marker = marker, previous_item = item})

            if item.include then
                items:append(item)
                item.index = #items
            else
                excluded_ranges:append(item.range)
            end
        end

        self:set_data("items", items)
        self:set_data("excluded_ranges", excluded_ranges)
    end

    self.excluded_ranges = excluded_ranges
    self.items = items
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

function Popup:count_words()
    local line_wordcounts = List(vim.api.nvim_buf_get_lines(self.source.buffer, 0, -1, true)):map(l -> #l:split(" "))

    self.excluded_ranges:foreach(function(range)
        for i = range[1] + 1, range[2] do
            line_wordcounts[i] = 0
        end
    end)

    self.wordcount = line_wordcounts:reduce("+")

    self.items:foreach(function(item)
        item.wordcount = 0
        for i = item.range[1] + 1, item.range[2] do
            item.wordcount = item.wordcount + line_wordcounts[i]
        end
    end)
end

-----------------------------------[ actions ]----------------------------------
function Popup.bind_heading_level_filter(level)
    return function(ui)
        ui.level = ui.level ~= level and level or #Heading.levels
        ui:update()
    end
end

function Popup.bind_meta_toggle(action, group)
    return function(ui)
        ui:toggle_meta(action, group)
        ui:update()
    end
end

Popup.keymap = List({
    {
        lhs = "<C-a>",
        desc = "show/hide parents",
        callback = function(ui)
            ui.show_lineage = not ui.show_lineage
            ui:update()
        end,
    },
    {
        lhs = "<C-w>",
        desc = "toggle wordcount",
        callback = function(ui)
            ui.show_wordcounts = not ui.show_wordcounts

            if ui.show_wordcounts then
                ui:count_words()
            end

            ui:update()
        end,
    },
    {
        lhs = "<C-/>",
        desc = "toggle meta filtering: all",
        callback = Popup.bind_meta_toggle("filter", "all"),
    },
    {
        lhs = "<C-,>",
        desc = "toggle meta filtering: create",
        callback = Popup.bind_meta_toggle("filter", "create"),
    },
    {
        lhs = "<C-.>",
        desc = "toggle meta filtering: change",
        callback = Popup.bind_meta_toggle("filter", "change"),
    },

    {
        lhs = "<M-/>",
        desc = "toggle meta collapse: all",
        callback = Popup.bind_meta_toggle("collapse", "all"),
    },
    {
        lhs = "<M-,>",
        desc = "toggle meta collapse: create",
        callback = Popup.bind_meta_toggle("collapse", "create"),
    },
    {
        lhs = "<M-.>",
        desc = "toggle meta collapse: change",
        callback = Popup.bind_meta_toggle("collapse", "change"),
    },

    {
        lhs = "<C-k>",
        desc = "leave subtree",
        callback = function(ui)
            ui.parent = nil
            ui:update()
        end,
    },
    {
        lhs = "<C-h>",
        desc = "enter parent subtree",
        callback = function(ui)
            if ui.parent then
                local parents = ui.parent.parents
                ui.parent = #parents > 0 and parents[1]
                ui:update()
            end
        end,
    },
    {
        lhs = "<C-l>",
        desc = "enter cursor subtree",
        callback = function(ui)
            ui.parent = ui.cursor.item

            -- when entering a parent of the filter level, increment it by 1
            if ui.level == ui.parent.level then
                ui.level = ui.level + 1
            end

            -- clear text on enter bc usually it was used to find the entered item
            ui.cursor.index = 1
            ui.input:clear()
            ui:update()
        end,
    },
    {
        lhs = "<CR>",
        desc = "go to heading",
        callback = function(ui)
            ui:close()
            ui_utils.set_cursor({row = ui.cursor.item.line})
        end,
    },
    {
        lhs = "<C-r>",
        desc = "insert heading reference",
        callback = function(ui)
            local reference = ui.cursor.item:get_reference()

            ui:close()

            local row, col = unpack(vim.api.nvim_win_get_cursor(0))

            local line = vim.api.nvim_get_current_line()
            local before = line:sub(1, col + 1)
            local after = line:sub(col + 2)

            vim.api.nvim_set_current_line(before .. reference .. after)
            vim.api.nvim_win_set_cursor(0, {row, col + 1 + #reference})
        end,
    },
})

for level = 1, #Heading.levels do
    Popup.keymap:append({
        lhs = ("<C-%d>"):format(level),
        desc = ("filter %d"):format(level),
        callback = Popup.bind_heading_level_filter(level),
    })
end

return function(args) return function() Popup:new(args) end end
