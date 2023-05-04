table = require("hl.table")
string = require("hl.string")
io = require("hl.io")
local Object = require("hl.object")
local Path = require("hl.path")

local Link = require("htl.text.link")
local Location = require("htl.text.location")


--------------------------------------------------------------------------------
--                                    Mark                                     
--------------------------------------------------------------------------------
-- format: [text]()
-- preceded by: any
-- followed by: Flag or none
--------------------------------------------------------------------------------
Mark = Object:extend()
Mark.defaults = {
    label = '',
    before = '',
    after = '',
}

function Mark:new(args)
    self = table.default(self, args or {}, self.defaults)
end

function Mark:__tostring()
    return tostring(Link({label = self.label}))
end

function Mark.from_str(str)
    local before, label, location, after = str:match(Link.regex)
    return Mark({label = label, before = before, after = after})
end

function Mark.str_is_a(str)
    if not Link.str_is_a(str) then
        return false
    end

    local before, label, location, after = str:match(Link.regex)

    if location:len() > 0 then
        return false
    end

    return true
end

function Mark.find(label, lines)
    for i, line in ipairs(lines) do
        if line:len() > 0 then
            if Mark.str_is_a(line) and Mark.from_str(line).label == label then
                return i
            end
        end
    end
    return nil
end



return Mark
