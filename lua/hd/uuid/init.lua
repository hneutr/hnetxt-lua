local socket = require("socket")
local charsets = require("hd.uuid.charset")

-- or: store last used integer on `.project`, increment it after making a new file

return function(charset_name)
    local charset = charsets[charset_name or "ascii"]
    local n = socket.gettime() * 10000
    local base = #charset

    n = math.floor(n)
    base = math.floor(base)

    local id = ""

    while n > 0 do
        id = charset[math.floor(n % base)] .. id
        n = math.floor(n / base)
    end

    return id
end
