local List = require("hl.List")
local Set = require("hl.Set")

local db = require("htl.db")
db.get()

local metadata = require("htl.db.metadata")
local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

print(#metadata:get())
-- local us = Set(metadata:get():col('url'))
-- print(us:len())

metadata:remove()

urls:get({where = {resource_type = "file"}}):sorted(function(a, b)
    return tostring(a.path) > tostring(b.path)
end):foreach(function(url)
    print(url.path)
    metadata:save_file_metadata(url.path)
end)
print(#metadata:get())
