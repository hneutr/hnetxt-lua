local M = class()

M.parts = List({"upper", "middle", "lower"})

function M:_init(args)
    args = args or {}
    self.size = args.size or Conf.header.size
    self.content = args.content or ''

    self = Dict.update(self, Conf.header, Conf.sizes[self.size])

    self.upper = self.upper .. self.fill:rep(self.width - 2) .. self.right
    self.lower = self.lower .. self.fill:rep(self.width - 2) .. self.right
end

function M:get_lines()
    return List({
        self.upper,
        self.middle .. " " .. self.content,
        self.lower,
    })
end

function M:__tostring()
    return self:get_lines():join("\n")
end

function M:get_pattern(line_type)
    return List({
        "^",
        self[line_type],
        line_type == "middle" and "%s.*" or "$",
    }):join("")
end

function M:str_is_upper(str)
    return str:match(self:get_pattern("upper")) or false
end

function M:str_is_lower(str)
    return str:match(self:get_pattern("lower")) or false
end

function M:str_is_middle(str)
    return str:match(self:get_pattern("middle")) or false
end

function M:str_is_a(str)
    return self:str_is_upper(str) or self:str_is_middle(str) or self:str_is_lower(str)
end

function M.headers()
    return Dict(Conf.sizes):keys():transform(function(s) return M({size = s}) end)
end

function M:syntax()
    local syntax = {}
    self.parts:foreach(function(line_type)
        syntax[self.size .. "Header" .. line_type] = {
            string = self:get_pattern(line_type):gsub("%%s.*", "\\s"),
            color = self.color,
        }
    end)
    return syntax
end

return M
