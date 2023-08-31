local socket = require("socket")
local charset = require("hd.uuid.charset")

return function()
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
