local socket = require("socket")

require("hl.string")
require("hl.Dict")

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

function M.formatkv(k, v, delimiter)
    return string.format("%s%s%s", k, delimiter or ": ", v)
end

function M.time_it(label)
    label = label or "time"
    TIME = TIME or socket.gettime() * 1000
    local now = socket.gettime() * 1000
    local str = string.format("%s: %d", label, now - TIME)
    print(str)
    TIME = now
    return str
end

function M.n_between(n, args)
    args = args or {}
    local exclusive = args.exclusive

    local min = args.min
    local max = args.max

    if exclusive then
        min = min + 1
        max = max - 1
    end

    if max < min then
        min, max = max, min
    end

    n = math.min(n, max)
    n = math.max(n, min)
    return n
end

return M
