local Path = require("hl.Path")

local dir = Path.home:join("corpus")

dir:glob("%.md$"):foreach(function(p)
    local lines = p:readlines()

    local modified = false
    lines:transform(function(line)
        if line:startswith("@self") then
            line = line:gsub("^@self", "@ego")
            modified = true
        end
        return line
    end)

    if modified then
        print(p)
        p:write(lines)
    end
end)
