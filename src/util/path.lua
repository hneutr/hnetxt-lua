local Path = {}
local lfs = require('lfs')
string = require("util.string")

-----------------------------------[ suffix ]-----------------------------------
-- dir/file.suffix → suffix
function Path.suffix(path)
    local pre, suffix = string.match(path, "(.*)%.(.%)")
    return suffix
end

-- dir/file.suffix → file
function Path.stem(path)
    if string.find(path, "/") ~= 0 then
        path = path:gsub(".*/", "")
    end

    local stem, suffix = path:match("(.*)%.(.*)")
    return stem
end

function Path.read(path)
    local file, errorString = io.open(path, "r")
    split = split or false

    local contents

    if file then
        contents = file:read("*a")
        io.close(file)

    else
        print( "File error: " .. errorString )
    end
    
    file = nil
    return contents
end

function Path.readlines(path)
    return string.split(Path.read(path), "\n")
end

------------------------------------[ trim ]------------------------------------
function Path.ltrim(path)
    local called_with = path
    path = path or ''
    path = tostring(path):gsub("^/", "", 1)
    return path
end

function Path.rtrim(path)
    local called_with = path
    path = path or ''
    path = tostring(path):gsub("/$", "", 1)
    return path
end

function Path.trim(path)
    return Path.ltrim(Path.rtrim(path))
end



function Path.join(left, right, ...)
    local path = tostring(Path.rtrim(left)) .. '/' .. tostring(Path.ltrim(right))
    path = Path.rtrim(path)

    if ... then
        path = Path.join(path, ...)
    end
    
    return path
end

function Path.listDir(dir)
    local items = {}
    local exclusions = {
        ["."] = true, 
        [".."] = true,
    }
    for stem in lfs.dir(dir) do
        if not exclusions[stem] then
            table.insert(items, Path.join(dir, stem))
        end
    end

    return items
end

return Path
