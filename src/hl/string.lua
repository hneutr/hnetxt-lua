local List = require("hl.List")
local Set = require("pl.Set")

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

PLAIN_DEFAULT = true

function _default_plain(plain)
    if plain == nil then
        plain = PLAIN_DEFAULT
    end
    return plain
end

function string.split(str, sep, maxsplit, plain)
    default_sep = " "
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
    
    return splits
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

function string.lstrip(str, charsToStrip)
    charsToStrip = charsToStrip or {"%s"}
    local pattern = string.format("^[%s]*(.*)", table.concat(charsToStrip))
    return str:match(pattern)
end

function string.rstrip(str, charsToStrip)
    return str:reverse():lstrip(charsToStrip):reverse()
end

function string.strip(str, charsToStrip)
    return str:lstrip(charsToStrip):rstrip(charsToStrip)
end

function string.removeprefix(str, prefix, plain)
    if str:startswith(prefix, plain) then
        str = str:sub(#prefix + 1)
    end

    return str
end

function string.removesuffix(str, suffix, plain)
    return str:reverse():removeprefix(suffix:reverse(), plain):reverse()
end

function string.partition(str, sep, plain)
    plain = _default_plain(plain)

    local sepIndex = str:find(sep, 1, plain)
    if sepIndex then
        pre = str:sub(1, sepIndex - 1)
        post = str:sub(sepIndex + #sep)
        return {pre, sep, post}
    end

    return {str, '', ''}
end

function string.rpartition(str, sep, plain)
    local reversedPartition = str:reverse():partition(sep:reverse(), plain)
    local partition = {}
    for i=#reversedPartition, 1, -1 do
        partition[#partition + 1] = reversedPartition[i]:reverse()
    end

    return partition
end

function string.rfind(str, substr, plain)
    plain = _default_plain(plain)
    local index = str:reverse():find(substr:reverse(), 1, plain)

    if index then
        index = #str - index
    end

    return index
end

function string.center(str, width, fillchar)
    fillchar = fillchar or " "

    while #str < width do
        str = fillchar .. str

        if #str < width then
            str = str .. fillchar
        end
    end

    return str
end

function string.escape(str)
    return str:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1')
end

--[[
https://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style/Titles_of_works#Capital_letters
https://en.wikipedia.org/wiki/List_of_English_prepositions
--]]
function string.title(str)
    local keep_lower = Set({
        -- articles
        "a", "an", "the",
        -- coordinating conjunctions
        "and", "but", "or", "nor", "for", "yet", "so",
        -- prepositions
        "a", "abt.", "aft", "ago", "amid", "anti", "as", "at", "atop", "away", "away",
        "back", "bar", "but", "by", "by",
        "chez", "come", "cum", "c̄",
        "down", "east", "ere", "for", "for", "for", "from", "from",
        "here", "home",
        "if", "in", "in", "into", "into",
        "less", "lest", "like", "like",
        "mid", "mod",
        "near", "next", "now", "now",
        "o'", "o'er", "of", "of", "off", "on", "on", "on", "on", "once", "onto", "out", "over", "over",
        "pace", "past", "per", "plus", "post", "pre", "pro",
        "qua",
        "re",
        "sans", "save", "save", "so", "sub",
        "t'", "than", "than", "then", "thru", "till", "till", "to", "to",
        "unto", "up", "upon", "upon",
        "via", "vice",
        "w/i", "w/o", "west", "when", "when", "with", "with",
    })

    local parts = List(str:split())
    for i, part in ipairs(parts) do
        part = part:lower()
        local start_char = part:sub(1, 1):upper()

        if keep_lower[part] and not (i == 1 or i == #parts) then
            start_char = start_char:lower()
        end

        parts[i] = start_char .. part:sub(2)
    end

    return parts:join(" ")
end

function string.rpad(str, width, char)
    char = char or " "

    return str .. char:rep(width - str:len())
end

function string.lpad(str, width, char)
    char = char or " "

    return char:rep(width - str:len()) .. str
end


return string
