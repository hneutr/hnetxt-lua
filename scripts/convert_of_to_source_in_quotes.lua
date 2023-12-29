local Path = require("hl.Path")

Path.home:join("eidola", "people"):glob("%.md$"):foreach(function(p)
    local lines = p:readlines()

    lines:put("is a: person")
    lines = lines:filter(function(line) return line ~= "is a: author" end)
    lines:transform(function(line)
        line = line:gsub("^%s*first:", "first name:")
        line = line:gsub("^%s*middle:", "middle name:")
        line = line:gsub("^%s*last:", "last name:")
        return line
    end)

    p:write(lines)
end)
