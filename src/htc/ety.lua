local Link = require("htl.text.Link")
local http = require("socket.http")
local htmlparser = require("htmlparser")

--[[
make a db to record where things are from?
]]

local M = {}
M.word_definition_prefix = "word__defination"
M.word_prefix = "word--"
M.related_word_prefix = "word_"
M.base_url = Path("https://www.etymonline.com")
M.word_url = M.base_url / "word"

function M.get_url(word)
    return tostring(M.word_url / word)
end

function M.is_a_word(div)
    local has_word_prefix = false
    local has_related_word_prefix = false
    for _class in List(div.classes):iter() do
        has_word_prefix = has_word_prefix or _class:startswith(M.word_prefix)
        has_related_word_prefix = has_related_word_prefix or _class:startswith(M.related_word_prefix)
    end
    return has_word_prefix and not has_related_word_prefix
end

function M.is_definition(section)
    for _class in List(section.classes):iter() do
        if _class:startswith(M.word_definition_prefix) then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  Elements                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Element = class()
Element.classes = List()
Element.name = nil

function Element:is_instance(e)
    if self.name and e.name ~= self.name then
        return false
    end

    local classes = Set(e.classes)

    for cls in self.classes:iter() do
        if not classes:has(cls) then
            return false
        end
    end

    return true
end

function Element:_init(e, str, args)
    args = args or {}
    self.str_start_i = args.start_i or 1

    self.e = e

    self.old = self.e:gettext():escape()
    self.new = self:get_new_str()

    self.start_i = str:find(self.old, self.str_start_i)
    self.end_i = self.start_i + #self.new

    self.str = str:gsub(self.old, self.new, 1)

    self.from = self:find_from()
end

function Element:get_word()
    return self.e:getcontent()
end

function Element:get_new_str() return self:get_word() end

function Element:find_from()
    local start_i = self.start_i - 1
    local pre = self.str:sub(self.str_start_i, start_i > 0 and start_i or 1)

    if pre:match("from") then
        local from = pre:split("from"):pop():strip()

        if from == "PIE root" then
            return "PIE"
        end

        if #from:split() < 5 then
            return from
        end
    end
end

function Element:ety_url()
    return M.word_url / self:get_word()
end

function Element:file_url()
    local word = self:get_word()
    word = word:gsub("^%*", "_")
    word = word:gsub("%-", "_")
    return Conf.paths.eidola_dir / "language" / string.format("%s.md", word)
end

--------------------------------------------------------------------------------
--                                  Foreign                                   --
--------------------------------------------------------------------------------
local Foreign = class(Element)
Foreign.classes = List({"foreign", "notranslate"})
Foreign.name = "span"

function Foreign:get_new_str()
    return string.format("_%s_", self:get_word())
end

--------------------------------------------------------------------------------
--                                 Reference                                  --
--------------------------------------------------------------------------------
local Reference = class(Element)
Reference.classes = List({"crossreference"})
Reference.name = "a"

function Reference:clean_href()
    local str = self.e.attributes.href

    local hashtag_i = str:find("#")

    if hashtag_i then
        str = str:sub(1, hashtag_i - 1)
    end

    return str
end

function Reference:get_word()
    return Path(self:clean_href()):name()
end

function Reference:get_new_str()
    local url

    if with_local then
        -- TODO!
        url = 1
    else
        url = M.base_url / self:clean_href()
    end

    return tostring(Link({label = self:get_word(), url = tostring(url)}))
end

function M.get_element(node, str, args)
    for ElementType in List({Reference, Foreign}):iter() do
        if ElementType:is_instance(node) then
            return ElementType(node, str, args)
        end
    end

    return
end

function M.get_section(word)
    local url = M.get_url(word)
    local body, code, headers, status = http.request(url)
    local root = htmlparser.parse(body)

    List(root:select("div")):filter(M.is_a_word):foreach(function(word_div)
        local section = List(word_div:select("section")):filter(M.is_definition):pop()

        List(section:select("p")):foreach(function(p)
            local str = p:getcontent()

            local start_i = 1
            List(p.nodes):foreach(function(node)
                if node.name == "strong" then
                    node = node.nodes[1]
                end

                local element = M.get_element(node, str, {start_i = start_i})

                if element then
                    str = element.str
                    start_i = element.end_i
                end
            end)

            str = clean_str(str)

            print(str)
            print(" ")
        end)
        print("----------------------------------------")
    end)
end

function clean_str(str)
    str = str:gsub("<strong>", "")
    str = str:gsub("</strong>", "")
    str = str:gsub("&quot;", '"')
    str = str:gsub("&#x27;", "'")
    str = str:gsub("%*", [[\*]])
    return str
end


return {
    description = "download a word from etymonline",
    {"word", args = "1", description = "word to download", default = "-ly"},
    {"+R", target = "download_references", description = "download references also", switch = "off"},
    action = function(args)
        M.get_section(args.word)
    end,
}
