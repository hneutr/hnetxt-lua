require("htl")

local M = {}

M.color_to_code = Dict()

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

function M.ansi_from_code(code)
    return string.format("%s[%dm", string.char(27), Conf.colors.term[code])
end

function M.get_code(color)
    if not M.color_to_code[color] then
        if color:startswith("#") then
            M.color_to_code[color] = M.ansi_from_hex(color)
        else
            M.color_to_code[color] = M.ansi_from_code(color)
        end
    end
    
    return M.color_to_code[color] or ""
end

function M.apply(str, colors)
    return string.format(
        "%s%s%s",
        List.as_list(colors):transform(M.get_code):join(""),
        tostring(str),
        M.get_code("reset")
    )
end

return function(items)
    return List(type(items[1]) == "string" and {items} or items):transform(function(item)
        return M.apply(unpack(item))
    end):join("")
end
