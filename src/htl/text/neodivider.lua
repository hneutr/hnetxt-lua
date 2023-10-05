local Dict = require("hl.Dict")
local List = require("hl.List")
local class = require("pl.class")

local Config = require("htl.config")

class.NDivider()
NDivider.config = Config.get("new_divider")
NDivider.sizes = Config.get("sizes")
NDivider.regex_info = {pre = "^", post = "$"}


function NDivider:_init(size)
    self = Dict.update(self, {size = size}, NDivider.config)
    self = Dict.update(self, self.config[self.size], self.sizes[self.size])
end

function NDivider:__tostring()
    return self.left .. self.fill:rep(self.width - 2, self.fill) .. self.right
end

function NDivider:regex()
    return "^" .. tostring(self) .. "$"
end

function NDivider:str_is_a(str)
    return str:match(self:regex())
end

function NDivider.by_size()
    local dividers = Dict()
    Dict(NDivider.sizes):keys():foreach(function(size)
        dividers[size] = NDivider(size)
    end)
    return dividers
end

function NDivider.divider_str_to_fold_level()
    -- local str_to_fold_level = {}
    -- NDivider.dividers_by_size():foreachv(function(divider)
    --     str_to_fold_level[tostring(divider)] = divider.fold_level
    -- end)

    -- return str_to_fold_level
end

function NDivider.parse_levels(lines)
    -- local divider_str_to_fold_level = NDivider.divider_str_to_fold_level()

    -- local current_level = 0
    -- return List(lines):map(function(line)
    --     current_level = divider_str_to_fold_level[line] or current_level
    --     return current_level
    -- end)
end

function NDivider.parse_divisions(lines)
    -- local divider_str_to_fold_level = Divider.divider_str_to_fold_level()

    -- local divs = List()
    -- for i, line in ipairs(lines) do
    --     if divider_str_to_fold_level[line] then
    --         if #divs == 0 or #divs[#divs] ~= 0 then
    --             divs:append(List())
    --         end
    --     else
    --         if #divs == 0 then
    --             divs:append(List())
    --         end

    --         divs[#divs]:append(i)
    --     end
    -- end

    -- if #divs[#divs] == 0 then
    --     divs:pop()
    -- end

    -- return divs
end

return NDivider
