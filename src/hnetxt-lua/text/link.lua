local Object = require("hneutil.object")
table = require("hneutil.table")

--------------------------------------------------------------------------------
--                                    Link                                     
--------------------------------------------------------------------------------
-- format: [label](location)
-- preceded by: any
-- followed by: any
--------------------------------------------------------------------------------
local Link = Object:extend()
Link.regex = "%s*(.-)%[(.-)%]%((.-)%)(.*)"
Link.defaults = {
    label = '',
    location = '',
    before = '',
    after = '',
}

function Link:new(args)
    self = table.default(self, args, self.defaults)
end

function Link.str_is_a(str)
    return str:match(Link.regex) ~= nil
end

function Link:__tostring()
    return "[" .. self.label .. "](" .. self.location .. ")"
end

function Link.from_str(str)
    local before, label, location, after = str:match(Link.regex)

    return Link({label = label, location = location, before = before, after = after})
end

function Link.get_nearest(str, position)
    local _start, _end = 0, 1

    local starts = {}
    local ends = {}
    local start_to_link = {}
    local end_to_link = {}
    while true do
        if Link.str_is_a(str) then
            local link = Link.from_str(str)

            _start = _end + link.before:len()
            start_to_link[_start] = link
            starts[#starts + 1] = _start

            _end = _start + tostring(link):len() + 1
            end_to_link[_end] = link
            ends[#ends + 1] = _end

            str = link.after
        else
            break
        end
    end

    table.sort(starts, function(a, b) return math.abs(a - position) < math.abs(b - position) end)
    table.sort(ends, function(a, b) return math.abs(a - position) < math.abs(b - position) end)

    local nearest_start = starts[1]
    local nearest_end = ends[1]

    if math.abs(nearest_start - position) <= math.abs(nearest_end - position) then
        return start_to_link[nearest_start]
    else
        return end_to_link[nearest_end]
    end
end

return Link
