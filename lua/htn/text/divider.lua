local Divider = require("htl.text.divider")

function Divider:syntax()
    return {
        [self.size .. self.style .. "Divider"] = {string = self:regex(), color = self.color}
    }
end

return Divider
