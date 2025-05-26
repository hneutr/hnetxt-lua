local M = class()

M.conf = Conf.text.heading

M.levels = List.range(1, 6):map(function(level)
    return {
        n = level,
        hl_group = ("markdownH%d"):format(level),
        bg_hl_group = ("RenderMarkdownH%dBg"):format(level),
        marker = ("#"):rep(level),
        selector = ("(atx_h%d_marker)"):format(level),
        indent = ("  "):format(level - 1),
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
    return text or str, Set(List(meta or {}):map(M.get_meta_conf))
end

function M:__tostring()
    return ("%s %s"):format(self.level.marker, self.str)
end

function M.str_is_a(str)
    return str and str:match("^#+%s.*")
end

function M.from_str(str, line)
    local level, str = str:match("(#+)%s(.*)")
    return M(str, #level, line)
end

function M:exclude_from_document()
    return M.conf.meta:map(function(conf)
        return conf.exclude and self.meta:has(conf.key) or nil
    end):any()
    -- local exclude = false
    -- print(self.meta)
    -- self.meta:vals():foreach(function(conf) exclude = exclude or conf.exclude end)
    -- return exclude
end

function M.get_meta_conf(char)
    for i, conf in ipairs(M.conf.meta) do
        if char == conf.char then
            return conf.key
        end
    end

    return {}
end

return M
