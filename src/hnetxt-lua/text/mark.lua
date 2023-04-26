table = require("hneutil.table")
string = require("hneutil.string")
io = require("hneutil.io")
local Object = require("hneutil.object")
local Path = require("hneutil.path")

local Link = require("hnetxt-lua.text.link")
local Location = require("hnetxt-lua.text.location")


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

return Mark
