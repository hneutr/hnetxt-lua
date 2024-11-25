local socket = require("socket")

require("hl.string")
require("hl.List")
require("hl.Dict")

local M = {}

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
    return ("%s%s%s"):format(k, delimiter or ": ", v)
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

function M.typify(object)
    if List.is_like(object) then
        object = List(object)
        object:transform(M.typify)
    elseif Dict.is_like(object) then
        object = Dict(object)
        object:transformv(M.typify)
    end

    return object
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    math                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function math.randint(args)
    args = Dict(args or {}, {min = 1, seed = os.time()})
    args.max = args.max or args.min

    math.randomseed(args.seed)
    return math.random(args.min, args.max)
end

function math.between(n, args)
    args = args or {}
    local exclusive = args.exclusive

    local min = args.min
    local max = args.max

    if exclusive then
        min = min + 1
        max = max - 1
    end

    max = max > min and max or min
    min = min < max and min or max

    n = math.min(n, max)
    n = math.max(n, min)
    return n
end

return M
