local M = class()

M.conf = Dict(Conf.text.heading)
M.conf.meta = Dict(M.conf.meta)

M.levels = List.range(1, 6):map(function(level)
    return {
        n = level,
        hl_group = string.format("markdownH%d", level),
        bg_hl_group = string.format("RenderMarkdownH%dBg", level),
        marker = string.rep("#", level),
        selector = string.format("(atx_h%d_marker)", level),
        indent = string.rep("  ", level - 1),
    }
end)

function M:_init(str, level, line)
    self.str = str
    self.level = self.levels[level]
    self.line = line

    self.text, self.meta = self.parse(self.str)
end

function M.parse(str)
    local text, meta = str:match(M.conf.patterns.meta)
    return text or str, List(meta or {}):map(M.get_meta_conf)
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
    local exclude = false
    self.meta:foreach(function(conf) exclude = exclude or conf.exclude end)
    return exclude
end

function M.get_meta_conf(char)
    for key, conf in pairs(M.conf.meta) do
        if char == conf.char then
            conf.key = key
            return conf
        end
    end

    return {}
end

return M
