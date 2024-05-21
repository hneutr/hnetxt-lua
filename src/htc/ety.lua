local Link = require("htl.text.Link")
local http = require("socket.http")
local htmlparser = require("htmlparser")

local M = {}
M.word_definition_prefix = "word__defination"
M.base_url = Path("https://www.etymonline.com")
M.word_url = M.base_url / "word"

function M.get_url(word)
    return tostring(M.word_url / word)
end

function M.get_word_from_reference(url)
    return tostring(Path(url):name())
end

function M.is_definition(section)
    for _class in List(section.classes):iter() do
        if _class:startswith(M.word_definition_prefix) then
            return true
        end
    end
    return false
end

function M.is_foreign(element)
    local classes = Set(element.classes)
    return element.name == "span" and classes:has("notranslate") and classes:has("foreign")
end

function M.replace_foreign(str, element)
    return str:gsub(
        element:gettext():escape(),
        string.format("_%s_", element:getcontent()),
        1
    )
end

function M.is_reference(element)
    return element.name == "a" and Set(element.classes):has("crossreference")
end

function M.get_reference_word(element)
    return Path(element.attributes.href):name()
end

function M.replace_reference(str, element, with_local)
    local url = element.attributes.href
    
    if with_local then
        -- TODO!
        url = 1
    else
        url = M.base_url / element.attributes.href
    end
    
    local label = string.gsub(element:getcontent(), "%*", [[\*]])
    local link = Link({label = label, url = tostring(url)})

    return str:gsub(
        element:gettext():escape(),
        tostring(link),
        1
    )
end



function M.get_section(word)
    local url = M.get_url(word)
    local body, code, headers, status = http.request(url)
    local root = htmlparser.parse(body)

    local sections = List(root:select("section")):filter(M.is_definition)
    local first_section = sections[1]
    
    local references = List()
    List(first_section:select("p")):foreach(function(p)
        local content = p:getcontent()
        List(p.nodes):foreach(function(node)
            if M.is_foreign(node) then
                content = M.replace_foreign(content, node)
            elseif M.is_reference(node) then
                references:append(M.get_reference_word(node))
                content = M.replace_reference(content, node)
            end
        end)
        
        content = content:gsub("&quot;", '"')
        content = content:gsub("&#x27;", "'")
        
        print(content)
        -- print(p:getcontent())
        os.exit()
        
    end)
end

function tag_text(tag)
    local text = tag:gettext()
    text = text:removesuffix(string.format("</%s>", tag.name))
    text = text:gsub(string.format("<%s*>", tag.name), "")
    
    return text
end

return {
    description = "download a word from etymonline",
    {"word", args = "1", description = "word to download", default = "test"},
    {"+R", target = "download_references", description = "download references also", switch = "off"},
    action = function(args)
        local url = "https://www.etymonline.com/word/test"
        M.get_section(args.word)
    end,
}
