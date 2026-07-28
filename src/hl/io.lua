local List = require("hl.List")

function io.command(command)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    return result
end

function io.list_command(command)
    return List(io.command(command):splitlines()):filter(function(line) return #line > 0 end)
end

return io
