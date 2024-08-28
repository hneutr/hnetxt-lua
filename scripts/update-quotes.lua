require("htl")

local dir = Conf.paths.eidola_dir / "media"

local quote_taxonomy_url = DB.urls:where({
    type = "taxonomy_entry",
    label = "quote",
})

local quote_urls = DB.Relations:get({
    where = {
        object = quote_taxonomy_url.id,
        relation = "instance",
    }
}):col('source')

local Parser = require("htl.Taxonomy.Parser")

local urls = DB.urls:get():filter(function(url)
    return quote_urls:contains(url.id)
end):sorted(function(a, b)
    return tostring(a.path) < tostring(b.path)
end):foreach(function(url)
    print(url.path)
    Parser:record(url)
    -- local lines = url.path:readlines()
    --
    -- local past_metadata = false
    -- local modified = false
    --
    -- local precount = #lines
    -- lines:transform(function(l)
    --     local _l = l:strip()
    --     if not past_metadata and #_l > 0 then
    --         if _l:startswith("source:") or _l:startswith("on page:") or _l:startswith("page:") or _l:startswith("@") then
    --             if _l:startswith("on page:") then
    --                 _l = _l:removeprefix("on ")
    --             end
    --
    --             modified = modified or l ~= _l
    --             l = _l
    --         end
    --     end
    --
    --     past_metadata = past_metadata or #l:strip() == 0
    --
    --     return l
    -- end)
    --
    -- if modified then
    --     if precount == #lines then
    --         url.path:write(lines)
    --     else
    --         print(url.path)
    --         print("lines changed")
    --         lines:foreach(print)
    --         os.exit()
    --     end
    -- end
end)
