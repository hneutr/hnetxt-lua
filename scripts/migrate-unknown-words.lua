local Path = require("hl.path")
local db = require("htl.db")

local urls = db.get().urls

print(require("inspect")(urls:where({path = "/Users/hne/Documents/text/written/fiction/chasefeel/a.md"})))
print(require("inspect")(urls:where({path = "/Users/hne/Documents/text/written/fiction/chasefeel/b.md"})))
