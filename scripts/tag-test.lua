require("htl")
local Parser = require("htl.Taxonomy.Parser")

-- local p = Path.home / "eidola" / "media" / "Gullivers-Travels" / "antient.md"
local p = Path.home / "eidola" / "media" / "Mirror-Dance" / "acerb.md"
local url = DB.urls:get_file(p)
local id_to_label = Dict.from_list(
    DB.urls:get(),
    function(u)
        return u.id, u.label
    end
)

Parser:record(url)

DB.Relations:get({
    where = {
        source = url.id,
        relation = {"tag", "connection"}
    }
}):foreach(function(r)
    local d = Dict({
        key = r.key,
        relation = r.relation,
        subject = string.format("%s (%d)", id_to_label[r.subject], r.subject),
    })
    
    if r.object then
        d.object = string.format("%s (%d)", id_to_label[r.object], r.object)
    end

    print(d)
end)
