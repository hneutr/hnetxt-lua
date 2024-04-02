local tbl = require("sqlite.tbl")

local M = tbl("log", {
    title = {
        "text",
        required = true,
        unique = true,
        primary = true,
    },
    date = {
        "text",
        default = os.date("%Y%m%d"),
    },
})

return M
