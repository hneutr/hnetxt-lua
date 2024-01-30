local Path = require("hl.path")
local db = require("htl.db")

local projects = db.get()['projects']
local urls = db.get()['urls']

print(#urls:get())

projects:get():foreach(function(project)
    urls:remove({project = project.title})
    project.path:iterdir({dirs = false}):foreach(function(path)
        urls:insert({path = path, project = project.title})
    end)
end)

print(#urls:get())
