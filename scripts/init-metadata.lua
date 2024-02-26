local List = require("hl.List")
local Set = require("hl.Set")

local db = require("htl.db")
db.get()

local metadata = require("htl.db.metadata")
local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

metadata:remove()

local u = List()
urls:get():sorted(function(a, b)
    return tostring(a.path) > tostring(b.path)
end):foreach(function(url)
    u:append(url.id)
    metadata:save_file_metadata(url.path)
end)
