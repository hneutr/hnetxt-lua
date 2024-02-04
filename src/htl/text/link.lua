local Dict = require("hl.Dict")
local class = require("pl.class")
local List = require("hl.List")

class.Link()
Link.regex = "(.-)%[(.-)%]%((.-)%)(.*)"

function Link:_init(args)
    self = Dict.update(self, args or {}, {
        label = '',
        location = '',
        before = '',
        after = '',
    })
end

function Link.str_is_a(str)
    return str:match(Link.regex) ~= nil
end

function Link:__tostring()
    return "[" .. self.label .. "](" .. self.location .. ")"
end

function Link.from_str(str)
    local before, label, location, after = str:match(Link.regex)
    return Link({
        label = label,
        location = location,
        before = before,
        after = after,
    })
end

function Link.get_nearest(str, position)
    local distance_to_link = Dict()

    local dist = 1
    while Link.str_is_a(str) do
        local link = Link.from_str(str)

        dist = dist + #link.before 
        distance_to_link[math.abs(dist - position)] = link
        dist = dist + #tostring(link) + 1
        distance_to_link[math.abs(dist - position)] = link

        str = link.after
    end

    local nearest_index = distance_to_link:keys():sort()[1]
    return distance_to_link[nearest_index]
end

function Link.find_label(label, lines)
    for i, line in ipairs(lines) do
        if #line > 0 then
            if Link.str_is_a(line) then
                local link = Link.from_str(line)
                if link.label == label and #link.location == 0 then
                    return i
                end
            end
        end
    end
    return nil
end

return Link
