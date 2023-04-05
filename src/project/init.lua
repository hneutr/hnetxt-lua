local lyaml = require("lyaml")
local t = lyaml.load("test: hunter\nline: [1, 2]")

-- local curDir = os.getenv("HOME") .. "/lib/hnetxt"
-- local path = curDir .. "/" .. "testfile.txt"
-- local testContents = require("util.path").read(path)
