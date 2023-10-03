local class = require("pl.class")
local Link = require("htl.text.link")

--------------------------------------------------------------------------------
--                                    Mark                                     
--------------------------------------------------------------------------------
-- format: [text]()
-- preceded by: any
-- followed by: Flag or none
--------------------------------------------------------------------------------
class.Mark(Link)

function Mark.from_str(str)
    return Link.from_str(str, Mark)
end

function Mark.str_is_a(str)
    return Link.str_is_a(str) and #Link.from_str(str, Mark).location == 0
end

function Mark.find(label, lines)
    for i, line in ipairs(lines) do
        if #line > 0 then
            if Mark.str_is_a(line) and Mark.from_str(line).label == label then
                return i
            end
        end
    end
    return nil
end

return Mark
