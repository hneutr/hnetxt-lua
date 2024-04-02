local tbl = require("sqlite.tbl")

local M = tbl("log", {
    id = true,
    key = {
        "text",
        required = true,
    },
    value = {
        "text",
        required = true,
    },
    date = {
        "text",
        default = os.date("%Y%m%d"),
    },
})

return M
