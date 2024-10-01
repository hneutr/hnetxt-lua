require("htl")

local tags = Set(DB.Relations:get({
    where = {relation = "tag"}
}):col('key')):vals():sorted():filter(function(t)
    return t:match("%.")
end)

tags:foreach(print)

local key = "place.description"

DB.Relations:get({
    where = {
        relation = "tag",
        key = key,
    }
}):foreach(function(r)
    local source_u = DB.urls:where({id = r.source})
    print(source_u.path)
end)
