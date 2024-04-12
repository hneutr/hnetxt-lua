local Path = require("hl.Path")

local Config = require("htl.Config")
require("htl.db").setup()

Conf.paths.language_dir:iterdir({dirs = false, recursive = false}):sort(function(a, b)
    return tostring(a) < tostring(b)
end):foreach(function(path)
    local first_line = path:readlines()[1]
    
    if first_line == "is a: root" then
        local new_path = path:with_stem("@" .. path:stem():sub(2))
        print(path)
        print(new_path)
        os.exit()
    end
end)
