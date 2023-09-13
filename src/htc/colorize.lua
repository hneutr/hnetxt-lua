local Colors = require("htc.colors")

return function(str, color)
    if color then
        str = Colors("%{" .. color .. "}" .. str .. "%{reset}")
    end

    return str
end
