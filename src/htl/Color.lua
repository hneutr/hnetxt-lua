require("htl")

local M = {}

M.color_to_code = Dict({
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

function M.hex_to_rgb(hex)
    hex = hex:removeprefix("#")
    return List({
        hex:sub(1, 2),
        hex:sub(3, 4),
        hex:sub(5, 6),
    }):transform(function(x)
        return tonumber("0x" .. x)
    end)
end

function M.ansi_from_hex(hex)
    return string.format("[38;2;%d;%d;%dm", unpack(M.hex_to_rgb(hex)))
end

function M.set_color(color)
    if not M.color_to_code[color] then
        if color:startswith("#") then
            M.color_to_code[color] = M.ansi_from_hex(color)
        end
    end
    
    M.color_to_code[color] = M.color_to_code[color] or M.color_to_code.reset
    
    return M.color_to_code[color]
end

return function(str, colors)
    str = tostring(str)

    List.as_list(colors):foreach(function(color)
        str = M.set_color(color) .. str .. M.set_color("reset")
    end)

    return str
end
