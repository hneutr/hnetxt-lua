class = require("pl.class")
function Class(tbl, parent)
    tbl = tbl or {}

    if parent then
        setmetatable(tbl, parent)
    end

    tbl.__index = tbl

    return tbl
end

require("hl.List")
require("hl.Dict")
require("hl.DefaultDict")
require("hl.Set")

require("hl.string")
require("hl.io")

require("hl.Path")
require("hl.Tree")

utils = require("hl.utils")

SqliteTable = require("sqlite.tbl")
