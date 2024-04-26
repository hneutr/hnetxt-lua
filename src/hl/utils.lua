require("hl.string")
local Dict = require("hl.Dict")

local M = {}

function M.randint(args)
    args = Dict(args or {}, {min = 1, seed = os.time()})
    args.max = args.max or args.min

    math.randomseed(args.seed)
    return math.random(args.min, args.max)
end

function M.parsekv(s, delimiter)
    delimiter = delimiter or ":"
    s = s or ""

    local key, val = unpack(s:split(delimiter, 1):mapm("strip"))
    
    if val and #val == 0 then
        val = nil
    end

    return key, val
end

return M
