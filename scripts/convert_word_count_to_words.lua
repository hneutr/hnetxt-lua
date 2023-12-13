local Track = require("htl.track")
local tracker = Track()
-- tracker.data_dir = require("hl.Path")("/Users/hne/lib/hnetxt-lua/scripts/htc-py/data/test-track-log")

-- tracker:entries():foreach(function(p)
--     local l = p:read()
--     l = l:gsub("morning todos", "todos")
--     p:write(l)
-- end)

tracker:create_csv()
