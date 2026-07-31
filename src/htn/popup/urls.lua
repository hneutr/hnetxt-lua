local ui_utils = require("htn.ui")
local popup = require("htn.popup")

--------------------------------------------------------------------------------
--                                   Symbol                                   --
--------------------------------------------------------------------------------
local Item = Class({}, popup.Item)

function Item:init(url)
    self.url = url
    self.dir, self.name = unpack(tostring(url.path):rsplit("/", 1))

    self.dir = self.dir:removeprefix(self.ui.projects[url.project])
    self.dir = self.dir:removeprefix("/")
    self.name = self.name:removesuffix(".md")

    self.string = #self.dir == 0 and self.name or ("%s/%s"):format(self.dir, self.name)
end

function Item:fuzzy_string()
    if self.ui.global then
        return ("@%s %s"):format(self.url.project, self.string)
    end

    return self.string
end

function Item:choice_string() return self:fuzzy_string() end

function Item:filter()
    local result = true

    if not self.ui.global and self.ui.project then
        result = result and self.url.project == self.ui.project
    end

    return result and self:fuzzy_match()
end

function Item:highlight(line)
    local highlights = List({
        {string = self.ui.global and ("@" .. self.url.project .. " "), group = "Special"},
        {string = #self.dir > 0 and self.dir .. "/", group = "Function"},
        {string = self.name, group = "Structure"},
    })

    local start = 0
    local stop = 0
    highlights:foreach(function(highlight)
        if highlight.string then
            stop = start + #highlight.string
            self.ui.choices:add_highlight(highlight.group, line, start, stop)
            start = stop
        end
    end)
end

--------------------------------------------------------------------------------
--                                   Choices                                  --
--------------------------------------------------------------------------------
local Choices = Class({}, popup.Choices)

function Choices:update()
    self.items = self.ui.items:filterm("filter"):sorted(|a, b| -> a.score < b.score)
end

--------------------------------------------------------------------------------
--                                    Popup                                   --
--------------------------------------------------------------------------------
local Popup = Class({
    name = "urls",
    Choices = Choices,
    dimensions = {
        width = 100,
        height = 51,
    },
}, popup.Popup)

function Popup:init(args)
    self.global = args.global == nil and true or args.global
    self:set_data()
end

function Popup:set_data()
    if not self.projects then
        self.projects = Dict()
        DB.projects:get():foreach(function(p) self.projects[p.title] = tostring(p.path) end)
    end

    local project = DB.projects.get_by_path(Path.this()) or {}
    self.project = project.title

    if not self.project then
        self.global = true
    end

    self.items = DB.urls:get({where = {type = "file"}}):map(url -> Item:new(self, url))
end

function Popup:title() return not self.global and self.project end

-----------------------------------[ actions ]----------------------------------
function Popup.bind_open_operation(operation)
    return function(ui)
        ui:close()

        local item = ui.cursor.item

        if ui.source.mode == 'i' then
            local cur = vim.fn.getpos('.')

            local line = ui_utils.get_cursor_line()
            local before = line:sub(1, cur[3] - 1)
            local after = line:sub(cur[3])

            local text = tostring(DB.urls:get_reference(item.url))

            cur[3] = #before + #text + 1

            ui_utils.set_cursor_line(before .. text .. after)
            vim.fn.setpos('.', cur)
        else
            vim.cmd(("silent %s %s"):format(operation, tostring(item.url.path)))
        end
    end
end

Popup.keymap = List({
    {
        lhs = "<C-2>",
        desc = "toggle global/local scope",
        callback = function(ui)
            if ui.project then
                ui.global = not ui.global
                ui:update()
            end
        end,
    },
})

List({
    {lhs = "<CR>",  op = "edit"},
    {lhs = "<C-l>", op = "vsplit"},
    {lhs = "<C-j>", op = "split"},
    {lhs = "<C-t>", op = "tabedit"},
}):foreach(function(map)
    Popup.keymap:append({
        lhs = map.lhs,
        desc = ("%s url"):format(map.op),
        callback = Popup.bind_open_operation(map.op)
    })
end)

return function(args) return function() Popup:new(args) end end
