require("htl")

local dir_s = "/Users/hne/eidola"
local dir = Path(dir_s)
local urls = DB.urls:get({where = {project = "eidola", type = "file"}}):sorted(function(a, b)
    return tostring(a.path) < tostring(b.path)
-- end):filter(function(u)
--     if u.path:parent() == media_dir then
--         return true
--     elseif u.path:name() == "@.md" then
--         return true
--     end
--     return false
end):foreach(function(u)
    local n_meta = #DB.Metadata:get({where = {subject = u.id}})
    if n_meta == 0 then
        DB.Metadata.record(u)
        local new_n = #DB.Metadata:get({where = {subject = u.id}})
        print(("%s: 0 → %d"):format(tostring(u.path:relative_to(dir)), new_n))
    end
    -- local lines = u.path:readlines()
    -- local changed = false
    --
    -- for i, line in ipairs(lines) do
    --     if #line:strip() == 0 then
    --         break
    --     end
    --
    --     lines[i] = line:strip()
    --     changed = lines[i] ~= line
    -- end
    --
    -- if changed then
    --     print(u.path)
    --     u.path:write(lines)
    --     DB.Metadata.record(u)
    -- end
end)

-- local book_ids = DB.Metadata:get({where = {predicate = "instance", object = 8290}}):col('subject'):sorted()
-- book_ids:foreach(function(id)
--     local url = DB.urls:where({id = id})
--     print(url)
-- end)

-- DB.Metadata.record(DB.urls:where({id = 5177}))
-- DB.Metadata:get({where = {subject = 5177}}):foreach(Dict.print)
