local List = require("hl.List")

-- ljust
-- rjust

-- lower
-- upper
-- capitalize

-- casefold
-- count
-- encode
-- expandtabs
-- format
-- format_map
-- isalnum
-- isalpha
-- isascii
-- isdecimal
-- isdigit
-- isidentifier
-- islower
-- isnumeric
-- isprintable
-- isspace
-- istitle
-- isupper
-- maketrans
-- swapcase
-- title
-- translate
-- zfill

local function _default_plain(plain)
    return plain == nil and true or plain
end

function string.split(str, sep, maxsplit, plain)
    local default_sep = " "
    sep = sep or default_sep
    plain = _default_plain(plain)

    local splits = {}
    while #str > 0 and str:find(sep, 1, plain) do
        local sep_index = str:find(sep, 1, plain)
        if sep_index then
            splits[#splits + 1] = str:sub(1, sep_index - 1)
            str = str:sub(sep_index + #sep)
        end

        if maxsplit and maxsplit == #splits then
            break
        end
    end

    if type(str) == 'string' then
        splits[#splits + 1] = str
    end

    if sep == default_sep then
        local filtered_splits = {}
        for _, split in ipairs(splits) do
            if #split > 0 then
                filtered_splits[#filtered_splits + 1] = split
            end
        end
        splits = filtered_splits
    end

    return List(splits)
end


function string.rsplit(str, sep, maxsplit, plain)
    str = str:reverse()
    sep = sep:reverse()

    local splits = List.reverse(str:split(sep, maxsplit, plain))
    for i, split in ipairs(splits) do
        splits[i] = split:reverse()
    end

    return splits
end

function string.splitlines(str)
    return str:split("\n")
end

function string.startswith(str, prefix, plain)
    plain = _default_plain(plain)
    return str:find(prefix, 1, plain) == 1
end

function string.endswith(str, suffix, plain)
    return str:reverse():startswith(suffix:reverse(), plain)
end

function string.join(sep, strs)
    local joined = ""
    for _, str in ipairs(strs) do
        if #joined > 0 then
            joined = joined .. sep
        end


        joined = joined .. str
    end

    return joined
end

function string.lstrip(str, chars)
    return str:match(("^[%s]*(.*)"):format(table.concat(chars or {"%s"})))
end

function string.rstrip(str, chars)
    return str:reverse():lstrip(chars):reverse()
end

function string.strip(str, chars)
    return str:lstrip(chars):rstrip(chars)
end

function string.removeprefix(str, prefix, plain)
    if str:startswith(prefix, plain) then
        return str:sub(#prefix + 1), true
    end

    return str, false
end

function string.removesuffix(str, suffix, plain)
    if str:endswith(suffix, plain) then
        return str:sub(1, #str - #suffix), true
    end

    return str, false
end

function string.partition(str, seps, maxpartition, plain)
    plain = _default_plain(plain)

    seps = List.as_list(seps)

    local parts = List({str})
    local n = 0

    repeat
        local str = parts:pop()
        local subparts
        local i
        seps:foreach(function(sep)
            local _i = str:find(sep, 1, plain)
            if _i and (not i or _i < i) then
                i = _i
                subparts = {str:sub(1, i - 1), sep, str:sub(i + #sep)}
            end
        end)

        parts:extend(subparts or {str})
        n = i and n + 1 or maxpartition
    until n == maxpartition

    return parts:filter(function(s) return #s > 0 end)
end

function string.rpartition(str, seps, maxpartition, plain)
    return str:reverse():partition(
        List.as_list(seps):map(string.reverse),
        maxpartition,
        plain
    ):clone():reverse():map(string.reverse)
end

function string.rfind(str, substr, plain)
    local index = str:reverse():find(substr:reverse(), 1, _default_plain(plain))
    return index and #str - index or index
end

function string.center(str, width, fillchar)
    fillchar = fillchar or " "

    while #str < width do
        str = fillchar .. str
        str = #str < width and (str .. fillchar) or str
    end

    return str
end

function string.escape(str)
    return str:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1')
end

function string.rpad(str, width, char)
    return str .. (char or " "):rep(width - str:len())
end

function string.lpad(str, width, char)
    return (char or " "):rep(width - str:len()) .. str
end

function string.bisect(str, index)
    index = math.min(index == nil and #str or index, #str)

    local left = index > 0 and str:sub(1, index) or ""
    local right = str:sub(math.max(1, index + 1))

    return left, right
end

return string
