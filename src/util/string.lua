function string.split(str, sep)
    local sep = sep or " "

    local fields = {}
    
    local pattern = string.format("([^%s]+)", sep)

    string.gsub(str, pattern, function(c) fields[#fields + 1] = c end)
    
    return fields
end

return string
