local Path = require("hl.path")
local db = require("htl.db")

local urls = db.get()['urls']

function get_links()
    return urls:get({where = {resource_type = "link"}})
end

function print_count(label)
    print(string.format("%s: %d", label, #get_links()))
end

print_count("before")

local to_remove = get_links():transform(function(l) return l.id end)

if #to_remove > 0 then
    urls:remove({id = to_remove})
    print_count("after")
end
