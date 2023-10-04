local List = require("hl.List")
local Dict = require("hl.Dict")
local class = require("pl.class")
local Config = require("htl.config")

class.NHeader()
NHeader.config = Config.get("new_header")

NHeader.regex_info = Dict({
    upper = {pre = "^", post = "$"},
    middle = {pre = "^", post = "%s.*"},
    lower = {pre = "^", post = "$"},
})

function NHeader:_init(args)
    self = Dict.update(self, args or {}, {size = NHeader.config.default_size, content = ''})
    self = Dict.update(self, self.config.defaults, self.config.sizes[self.size])

    self.line_templates = Dict({
        upper = self.upper:rpad(self.width, self.fill),
        middle = self.middle,
        lower = self.lower:rpad(self.width, self.fill),
    })
end

function NHeader:middle_line()
    return self.middle .. " " .. self.content
end

function NHeader:get_lines()
    return List({self.line_templates.upper, self:middle_line(), self.line_templates.lower})
end

function NHeader:__tostring()
    return self:get_lines():join("\n")
end

function NHeader:get_pattern(line_type)
    local regex_info = NHeader.regex_info[line_type]

    return List({
        regex_info.pre or "",
        self.line_templates[line_type],
        regex_info.post or "",
    }):join("")
end

function NHeader:str_is_upper(str)
    return str:match(self:get_pattern("upper")) or false
end

function NHeader:str_is_lower(str)
    return str:match(self:get_pattern("lower")) or false
end

function NHeader:str_is_middle(str)
    return str:match(self:get_pattern("middle")) or false
end

function NHeader:str_is_a(str)
    return self:str_is_upper(str) or self:str_is_middle(str) or self:str_is_lower(str)
end

function NHeader:strs_are_a(l1, l2, l3)
    return self:str_is_upper(l1) and self:str_is_middle(l2) and self:str_is_lower(l3)
end

function NHeader.headers_by_size()
    local headers = Dict()
    Dict(NHeader.config.sizes):keys():foreach(function(size)
        headers[size] = NHeader({size = size})
    end)
    return headers
end

return NHeader
