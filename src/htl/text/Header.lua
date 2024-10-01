local M = class()

function M:_init(str, level, line)
    self.str = str
    self.level = level
    self.line = line
    
    self:parse_str(self.str)
end

function M:parse_str(str)

    if str:match(Conf.text.header_label) then
        self.label, self.text = str:match(Conf.text.header_label)
    else
        self.label, self.text = "", str
    end
end

function M:__tostring()
    return string.format("%s %s", string.rep("#", self.level), self.str)
end

function M:color()
    return VimColor.get_hl_attr(
        string.format("markdownH%d", self.level),
        "fg"
    )
end

function M:fuzzy_str()
    return string.rep("  ", self.level - 1) .. TermColor(self.str, self:color())
end

function M.str_is_a(str)
    return str and str:match("^#+%s.*")
end

function M.from_str(str, line)
    local level, str = str:match("(#+)%s(.*)")
    return M(str, #level, line)
end

function M:exclude_from_document()
    return self.text:match(Conf.text.exclude_header_from_document) ~= nil
end

return M
