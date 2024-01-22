local sqlite = require("sqlite.db")
-- local tbl = require("sqlite.tbl")

-- local strftime = sqlite.lib.strftime

local Config = require("htl.config")
-- local uri = "/tmp/bm_db_v1"

return {
    uri = Config.data_dir:join(Config.get("db").path)
}
--M.uri = Config.data_dir:join(Config.get("db").path)

----[[ Datashapes ---------------------------------------------
--@class BMCollection
--@field title string: collection title

--@class BMEntry
--@field id number: unique id
--@field link string: file or web link.
--@field title string: the title of the bookmark.
--@field doc number: date of creation.
--@field type BMType
--@field count number: number of times it was clicked.
--@field collection string: foreign key referencing BMCollection.title.

--@class BMTimeStamp
--@field id number: unique id
--@field timestamp number
--@field entry number: foreign key referencing BMEntry

----]]

----[[ sqlite classes ------------------------------------------
--@class BMEntryTable: sqlite_tbl

--@class BMDatabase: sqlite_db
--@field entries BMEntryTable

--@field collection sqlite_tbl
--@field ts sqlite_tbl

----]]

----- 3. Construct
-----------------------------

--local entries = tbl("entries", {
--    id = true, -- same as { type = "integer", required = true, primary = true }
--    link = {"text", required = true},
--    title = "text",
--    since = {"date", default = strftime("%s", "now")},
--    count = {"number", default = 0},
--    type = {"text", required = true},
--    collection = {
--        type = "text",
--        reference = "collection.title",
--        on_update = "cascade", -- means when collection get updated update
--        on_delete = "null", -- means when collection get deleted, set to null
--    },
--})

--local collection = tbl("collection", {
--    title = {
--        "text",
--        required = true,
--        unique = true,
--        primary = true,
--    },
--})

----------------------------------------------------------------------------------
----                                                                            --
----                                 timestamps                                 --
----                                                                            --
----------------------------------------------------------------------------------
--local timestamps = tbl("timestamps", {
--    id = true,
--    timestamp = {"real", default = sqlite.lib.julianday("now")},
--    entry = {
--        type = "integer",
--        reference = "entries.id",
--        on_delete = "cascade", --- when referenced entry is deleted, delete self
--    },
--})

-----Insert timestamp entry
-----@param id number
--function timestamps:insert(id)
--    timestamps:__insert({ entry = id})
--end

-----Get timestamp for entry.id or all
-----@param id number|nil: BMEntry.id
-----@return BMTimeStamp
--function timestamps:get(id)
--    return timestamps:__get({ --- use "self.__get" as backup for overriding default methods.
--        where = id and {
--            entry = id,
--        } or nil,
--        select = {
--            age = (strftime("%s", "now") - strftime("%s", "timestamp")) * 24 * 60,
--            "id",
--            "timestamp",
--            "entry",
--        },
--    })
--end

-----Trim timestamps entries
-----@param id number: BMEntry.id
--function timestamps:trim(id)
--    local rows = timestamps:get(id) -- calling t.get defined above
--    local trim = rows[(#rows - 10) + 1]
--    if trim then
--        timestamps:remove { id = "<" .. trim.id, entry = id }
--        return true
--    end
--    return false
--end


-----Update an entry values
-----@param row BMEntry
--function entries:edit(id, row)
--    entries:update({
--        where = { id = id },
--        set = row,
--    })
--end

-----Increment row count by id.
--function entries:inc(id)
--    local row = entries:where { id = id }
--    entries:update {
--        where = { id = id },
--        set = { count = row.count + 1 },
--    }
--    timestamps:insert(id)
--    timestamps:trim(id)
--end

-----Add a row
-----@param row BMEntry
--function entries:add(row)
--    if row.collection and not collection:where { title = row.collection } then
--        collection:insert { title = row.collection }
--    end

--    row.type = row.link:match "^%w+://" and "web" or (row.link:match ".-/.+(%..*)$" and "file" or "dir")

--    local id = entries:insert(row)
--    if not row.title and row.type == "web" then
--        local ok, curl = pcall(require, "plenary.curl")
--        if ok then
--            curl.get { -- async function
--                url = row.link,
--                callback = function(res)
--                    if res.status ~= 200 then
--                        return
--                    end
--                    entries:update {
--                        where = { id = id },
--                        set = { title = res.body:match "title>(.-)<" },
--                    }
--                end,
--            }
--        end
--    end

--    timestamps:insert(id)

--    return id
--end

--local ages = {
--    [1] = { age = 240, value = 100 }, -- past 4 hours
--    [2] = { age = 1440, value = 80 }, -- past day
--    [3] = { age = 4320, value = 60 }, -- past 3 days
--    [4] = { age = 10080, value = 40 }, -- past week
--    [5] = { age = 43200, value = 20 }, -- past month
--    [6] = { age = 129600, value = 10 }, -- past 90 days
--}

-----Get all entries.
-----@param q sqlite_query_select: a query to limit the number entries returned.
-----@return BMEntry
--function entries:get(q)
--    local items = entries:map(function(entry)
--        local recency_score = 0
--        if not entry.count or entry.count == 0 then
--            entry.score = 0
--            return entry
--        end

--        for _, _ts in pairs(timestamps:get(entry.id)) do
--            for _, rank in ipairs(ages) do
--                if _ts.age <= rank.age then
--                    recency_score = recency_score + rank.value
--                    -- goto continue
--                end
--            end
--            -- ::continue::
--        end

--        entry.score = entry.count * recency_score / 10
--        return entry
--    end, q)

--    table.sort(items, function(a, b)
--        return a.score > b.score
--    end)

--    return items
--end

--function M.get()
--    return sqlite({
--        uri = M.uri,
--        entries = entries,
--        collection = collection,
--        timestamps = timestamps,
--    })
--end

--return M
