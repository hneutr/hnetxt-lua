local htl = require("htl")

local today = os.date("%Y%m%d")
local d1 = htl.test_dir / "dir-1"
local f1 = d1 / string.format("%s.md", today)
local f2 = d1 / "19930120.md"

local M

before_each(function()
    htl.before_test()
    M = DB.Log
end)

after_each(htl.after_test)

describe("should_delete", function()
    it("+", function()
        assert(M:should_delete("19930120"))
    end)
    
    it("-", function()
        assert.is_false(M:should_delete(os.date("%Y%m%d")))
    end)
end)

describe("clean", function()
    it("keep", function()
        f1:touch()
        assert(f1:exists())
        M.clean(f1)
        assert(f1:exists())
    end)
    
    it("delete", function()
        f2:touch()
        assert(f2:exists())
        M.clean(f2)
        assert.is_false(f2:exists())
    end)
end)

describe("parse_line", function()
    it("empty", function()
        assert.are.same({}, M.parse_line(""))
    end)
    
    it("+", function()
        assert.are.same({key = "a", val = "b", date = 1}, M.parse_line("  a: b", 1))
    end)
end)


describe("record", function()
    it("existing rows deleted", function()
        local row = {date = f1:stem(), key = "key", val = "val"}
        M:insert(row)
        assert(M:where(row))
        f1:touch()
        M.record(f1)
        assert.is_nil(M:where(row))
    end)
    
    it("inserts new rows", function()
        local row = {date = f1:stem(), key = "key", val = "val"}
        M:insert(row)
        assert(M:where(row))

        f1:write({
            "a: b",
            "c: d",
        })
        M.record(f1)

        assert(M:where({date = f1:stem(), key = "a", val = "b"}))
        assert(M:where({date = f1:stem(), key = "c", val = "d"}))
        assert.are.same(2, #M:get())
    end)
end)

describe("get_lines", function()
    local date = os.date("%Y%m%d")
    local to_track_lines = List({
        "a: x",
        "a.b: y",
        "c: z",
    })

    before_each(function()
        Conf.paths.to_track_file:write(to_track_lines)
    end)

    it("nothing in the db", function()
        assert.are.same(to_track_lines, M.get_lines(date))
    end)

    it("something in the db", function()
        DB.Log:insert({date = date, key = "a", val = "w"})
        
        assert.are.same(
            {
                "a: w",
                "a.b: y",
                "c: z",
            },
            M.get_lines(date)
        )
    end)
end)
