local Path = require("hl.Path")
local List = require("hl.List")

local source_dir = Path.home:join("Documents", "text", "words", "unknown")
local eidola_dir = Path.home:join("eidola")
local media_dir = eidola_dir:join("media")

local lowercase_title_to_media_dir = Dict()
media_dir:iterdir({files=false, recursive=false}):foreach(function(p)
    local name = p:stem():lower()
    lowercase_title_to_media_dir[name] = p
end)

function get_word_file(path)
    local title = tostring(path:stem()):gsub("%-", " ")
    local location = tostring(path:join("@.md"):relative_to(eidola_dir))
    return {
        "is a: word",
        "  @unknown",
        "source: [" .. title .. "](" .. location .. ")"
    }
end

source_dir:glob("%.md$"):foreach(function(p)
    local author, book = unpack(p:stem():split("_", 1))
    local book_dir = lowercase_title_to_media_dir[book]

    if book_dir then
        p:readlines():foreach(function(word)
            if word:match(":") then
                word = word:split(":", 1)[1]
            end

            if #word > 0 then
                local word_path = book_dir:join(word .. ".md")
                word_path:write(get_word_file(book_dir))
            end
        end)

        p:unlink()
    end
end)
