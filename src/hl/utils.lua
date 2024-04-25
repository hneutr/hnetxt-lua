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
    return unpack(s:split(delimiter, 1):mapm("strip"))
end

return M
