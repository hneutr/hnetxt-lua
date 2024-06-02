require("htl")
local TP = require("htl.Taxonomy.Parser")

DB.Relations:get({
    contains = {
        key = "juvenalia*",
    }
}):col('source'):sorted():foreach(function(s)
    local u = DB.urls:where({id = s})
    print(u.path)
    TP:record(u)
end)
