local List = require("hl.List")
local Dict = require("hl.Dict")

local color_to_code = Dict({
    reset        = 0,
    bright       = 1,
    dim          = 2,
    underline    = 4,
    blink        = 5,
    reverse      = 7,
    hidden       = 8,

    -- foreground
    black        = 30,
    red          = 31,
    green        = 32,
    yellow       = 33,
    blue         = 34,
    magenta      = 35,
    cyan         = 36,
    white        = 37,

    -- background
    blackbg      = 40,
    redbg        = 41,
    greenbg      = 42,
    yellowbg     = 43,
    bluebg       = 44,
    magentabg    = 45,
    cyanbg       = 46,
    whitebg      = 47,
}):transformv(function(v)
    return string.format("%s[%dm", string.char(27), v)
end)

local function escape_keys(_, str)
    return List(str:gmatch("%w+")):transform(function(s) return color_to_code[s] end):join()
end

return function(str, color)
    local colors
    if type(color) == "table" then
        colors = List(color)
    else
        colors = List({color})
    end

    colors:foreach(function(color)
        str = "%{" .. (color or "reset") .. "}" .. str .. "%{reset}"
    end)
    return str:gsub("(%%{(.-)})", escape_keys)
end
