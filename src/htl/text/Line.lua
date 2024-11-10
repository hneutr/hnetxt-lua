local M = class()
M.name = "line"

M.regex = "^(>?)(%s*)(.*)$"

function M:_init(str)
    Dict.update(self, self.parse(str))
    self.conf = self.conf or {name = "line"}
end

function M:__tostring()
    return List({
        self.quote,
        self.indent,
        self.text,
    }):join()
end

function M.parse(l)
    l = type(l) == "string" and l or tostring(l)

    local quote, indent, text = l:match(M.regex)

    if #quote > 0 and #indent % 2 == 1 then
        quote = quote .. " "
        indent = indent:sub(2)
    end

    return {quote = quote, indent = indent, text = text}
end

function M.str_is_a() return true end

function M:get_next(text)
    local next = getmetatable(self)(tostring(self))
    next.text = text or ""
    return next
end

function M.transform(lines) return lines end

return M
