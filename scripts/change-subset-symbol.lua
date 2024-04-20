require("htl")

Path("/Users/hne/Documents/text/written/fiction/chasefeel/glossary"):iterdir({dirs = false}):sorted(function(a, b)
    return tostring(a) < tostring(b)
end):foreach(function(p)
    local content = p:read()
    
    if content:match("⊂") then
        content = content:gsub("⊂", "⊃")
        p:write(content)
    end
end)
