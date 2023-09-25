local List = require("hl.List")
local Dict = require("hl.Dict")
local config = require("htl.config").get("monoheader")

local class = require("pl.class")

class.Header()

Header.defaults = config.defaults
Header.sizes = config.sizes

function Header:_init(args)
    self = Dict.update(
        self, 
        Dict(args, self.sizes[args.size or self.defaults.size], self.defaults),
        {label = function() return "" end}
    )
end

-- function Header:components()
-- end
function Header:get_label()
    local label = self.label
    if type(label) == "function" then
        label = self.label()
    end

    return label
end

function Header:__tostring()
    local s = self.pre .. self:get_label() .. self.post
    local fill_len = self.width - self.open:len() - self.close:len()
    return self.open .. s:center(fill_len, self.fill) .. self.close
end

-- function Header:str_is_a(str)
--     return Header.str_is_a(str, self.uuid)
-- end

-- function Header.str_is_a(str, uuid)
--     if Link.str_is_a(str) then
--         local link = Link.from_str(str)
--         if link.before == Header.link_char and link.after == ":" then
--             if uuid == nil or link.location == uuid then
--                 return true
--             end
--         end
--     end

--     return false
-- end

-- function Header:components()
--     return List.from(
--         {
--             tostring(self.divider),
--             self.link_char .. "[",
--             self.label,
--             "](",
--             self.uuid,
--             "):"
--         },
--         self:get_field_strings(),
--         {tostring(self.divider)}
--     )
-- end

-- function Header:__tostring()
--     return Text.components_to_lines(self:components()):join("\n")
-- end

function Header:before() return {} end
function Header:after()
    local before = self:before()

    local after = {}
    for i = #before, 1, -1 do
        table.insert(after, before[i])
    end

    return after
end

-- function Header:set_text(text)
--     Header.super.set_text(self, text)

--     self.to_fill = {total = self.width - self.text:len()}
--     self.to_fill.left = math.max(math.floor(self.to_fill.total / 2), self.comment:len())
--     self.to_fill.right = math.max(self.to_fill.total - self.to_fill.left, self.comment:len())
-- end

-- function Header:side_fill(side)
--     local str = self.comment
--     str = str .. string.rep(self.input_fill_char, self.to_fill[side] - str:len())

--     if side == 'right' then
--         str = str:reverse()
--     end

--     return str
-- end

-- function Header.side_fill_fn(args, _, user_args)
--     local text = args[1][1]
--     local obj, side = unpack(user_args)
--     obj:set_text(text)
--     return obj:side_fill(side)
-- end

-- function Header:get_text_snip(text)
--     if text then
--         return t(text)
--     end
-- end

-- function Header:snippet()
--     return {
--         self:get_text_snip(self:before()),
--         f(Header.side_fill_fn, {1}, {user_args = {{self, 'left'}}}),
--         i(1),
--         f(Header.side_fill_fn, {1}, {user_args = {{self, 'right'}}}),
--         self:get_text_snip(self:after()),
--     }
-- end


return Header
