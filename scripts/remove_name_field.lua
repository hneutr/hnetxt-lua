local Path = require("hl.Path")

local dir = Path.home:join("eidola", "people")

dir:glob("%.md$"):foreach(function(p)
    local lines = p:readlines()

    if lines[1] == "is a: person" and lines[2] == "is a: person" then
        lines:pop(2)
        p:write(lines)
    end
end)
