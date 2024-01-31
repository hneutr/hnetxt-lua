local Path = require("hl.path")
local db = require("htl.db")

local mirror = require("htl.mirror")
local projects = db.get()['projects']
local urls = db.get()['urls']

print(#urls:get())

local project_roots = Dict()

projects:get():foreach(function(project)
    project_roots[project.title] = project.path
end)

local to_remove = List()
local paths = List()
urls:get():foreach(function(url)
    if url.path:relative_to(project_roots[url.project]):startswith(".") then
        print(url.path)
        to_remove:append(url.id)
    end
end)

urls:remove({id = to_remove})
-- print(#to_remove)
