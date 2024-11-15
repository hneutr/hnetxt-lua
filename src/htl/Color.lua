require("htl")

local M = {}

M.colors = {}

function M.hex_to_rgb(hex)
    hex = hex:removeprefix("#")
    return List({
        hex:sub(1, 2),
        hex:sub(3, 4),
        hex:sub(5, 6),
    }):map(function(x)
        return tonumber("0x" .. x)
    end)
end

function M.from_hex(hex)
    return ("[38;2;%d;%d;%dm"):format(unpack(M.hex_to_rgb(hex)))
end

function M.from_code(code)
    return ("[%dm"):format(code)
end

function M.define(color)
    color = Conf.colors.term[color] or Conf.colors.vim[color] or color
    return type(color) == "number" and M.from_code(color) or M.from_hex(color)
end

function M.get(color)
    M.colors[color] = M.colors[color] or M.define(color)
    return M.colors[color] or ""
end

function M.apply(str, colors)
    return string.format(
        "%s%s%s",
        List.as_list(colors):transform(M.get):join(""),
        tostring(str),
        M.get("reset")
    )
end

return function(items)
    return List(type(items[1]) == "string" and {items} or items):transform(function(item)
        return M.apply(unpack(item))
    end):join("")
end
