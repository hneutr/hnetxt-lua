local Dict = require("hl.Dict")
local List = require("hl.List")
local Object = require("hl.object")
local Config = require("htl.config")

local Divider = Object:extend()
Divider.config = Config.get("divider")

function Divider:new(size)
    self.size = size or self.config.default_size
    self.highlight_key = self.size .. "Divider"

    self = Dict.update(self, self.config.sizes[self.size])
end

function Divider:__tostring()
    local str = self.start_string
    return str .. string.rep(self.config.fill_char, self.width - (#str))
end

function Divider:line_is_a(index, lines)
    return tostring(self) == lines[index]
end

function Divider.dividers_by_size()
    local dividers = Dict()
    for size, _ in pairs(Divider.config.sizes) do
        dividers[size] = Divider(size)
    end

    return dividers
end

function Divider.divider_str_to_fold_level()
    local str_to_fold_level = {}
    Divider.dividers_by_size():foreachv(function(divider)
        str_to_fold_level[tostring(divider)] = divider.fold_level
    end)

    return str_to_fold_level
end

function Divider.parse_levels(lines)
    local divider_str_to_fold_level = Divider.divider_str_to_fold_level()

    local current_level = 0
    return List(lines):map(function(line)
        current_level = divider_str_to_fold_level[line] or current_level
        return current_level
    end)
end

function Divider.parse_divisions(lines)
    local divider_str_to_fold_level = Divider.divider_str_to_fold_level()

    local divs = List()
    for i, line in ipairs(lines) do
        if divider_str_to_fold_level[line] then
            if #divs == 0 or #divs[#divs] ~= 0 then
                divs:append(List())
            end
        else
            if #divs == 0 then
                divs:append(List())
            end

            divs[#divs]:append(i)
        end
    end

    if #divs[#divs] == 0 then
        divs:pop()
    end

    return divs
end

return Divider
