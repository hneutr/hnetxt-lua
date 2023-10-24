local List = require("hl.List")
local Dict = require("hl.Dict")
local class = require("pl.class")

local Config = require("htl.config")

class.Header()
Header.config = Config.get("header")
Header.sizes = Config.get("sizes")

Header.regex_info = Dict({
    upper = {pre = "^", post = "$"},
    middle = {pre = "^", post = "%s.*"},
    lower = {pre = "^", post = "$"},
})

function Header:_init(args)
    self = Dict.update(self, args or {}, {content = '', size = 'medium'})
    self = Dict.update(self, {middle = self.config.middle[self.size]}, self.config, self.sizes[self.size])

    self.line_templates = Dict({
        upper = self.upper .. self.fill:rep(self.width - 2) .. self.right,
        middle = self.middle,
        lower = self.lower .. self.fill:rep(self.width - 2) .. self.right,
    })
end

function Header:middle_line()
    return self.middle .. " " .. self.content
end

function Header:get_lines()
    return List({self.line_templates.upper, self:middle_line(), self.line_templates.lower})
end

function Header:__tostring()
    return self:get_lines():join("\n")
end

function Header:get_pattern(line_type)
    local regex_info = Header.regex_info[line_type]

    return List({
        regex_info.pre or "",
        self.line_templates[line_type],
        regex_info.post or "",
    }):join("")
end

function Header:str_is_upper(str)
    return str:match(self:get_pattern("upper")) or false
end

function Header:str_is_lower(str)
    return str:match(self:get_pattern("lower")) or false
end

function Header:str_is_middle(str)
    return str:match(self:get_pattern("middle")) or false
end

function Header:str_is_a(str)
    return self:str_is_upper(str) or self:str_is_middle(str) or self:str_is_lower(str)
end

function Header:strs_are_a(l1, l2, l3)
    return self:str_is_upper(l1) and self:str_is_middle(l2) and self:str_is_lower(l3)
end

function Header.headers()
    return Dict(Header.sizes):keys():transform(function(s)
        return Header({size = s})
    end)
end

function Header.by_size()
    local headers = Dict()
    Dict(Header.sizes):keys():foreach(function(size)
        headers[size] = Header({size = size})
    end)
    return headers
end

return Header
