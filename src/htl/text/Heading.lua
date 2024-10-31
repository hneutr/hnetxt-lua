local TermColor = require("htl.Color")

local M = class()

M.levels = List()

function M.get_level(level)
    if not M.levels[level] then
        local d = {
            n = level,
            hl_group = string.format("markdownH%d", level),
            bg_hl_group = string.format("RenderMarkdownH%dBg", level),
            marker = string.rep("#", level),
            selector = string.format("(atx_h%d_marker)", level),
            indent = string.rep("  ", level - 1),
        }

        M.levels[level] = d
    end

    return M.levels[level]
end

function M:_init(str, level, line)
    self.str = str
    self.level = self.get_level(level)
    self.line = line

    self:parse_str(self.str)
end

function M:parse_str(str)
    if str:match(Conf.text.heading_label) then
        self.text, self.label = str:match(Conf.text.heading_label)
    else
        self.text, self.label = str, ""
    end
end

function M:__tostring()
    return string.format("%s %s", self.level.marker, self.str)
end

function M.str_is_a(str)
    return str and str:match("^#+%s.*")
end

function M.from_str(str, line)
    local level, str = str:match("(#+)%s(.*)")
    return M(str, #level, line)
end

function M:exclude_from_document()
    return self.text:match(Conf.text.exclude_heading_from_document) ~= nil
end

function M:toggle_exclusion()
    if self:exclude_from_document() then
        self.text = self.text:removeprefix("{"):removesuffix("}")
    else
        self.text = string.format("{%s}", self.text)
    end

    if #self.label > 0 then
        self.str = string.format("%s [%s]", self.text, self.label)
    else
        self.str = self.text
    end
end

function M.from_marker_node(marker)
    local content_node = marker:next_sibling()

    local str = content_node and vim.treesitter.get_node_text(content_node, 0) or ""
    local level = tonumber(marker:type():match("atx_h(%d+)_marker"))
    local line = marker:start() + 1

    return M(str, level, line)
end

return M
