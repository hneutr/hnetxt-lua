local Path = require("hl.Path")

local Config = require("htl.Config")
local db = require("htl.db")
local Log = require("htl.db.Log")

local today = os.date("%Y%m%d")
local d1 = Config.test_root / "dir-1"
local f1 = d1 / string.format("%s.md", today)
local f2 = d1 / "19930120.md"

before_each(function()
    db.before_test()
end)

after_each(function()
    db.after_test()
end)

describe("should_delete", function()
    it("+", function()
        assert(Log:should_delete("19930120"))
    end)
    
    it("-", function()
        assert.is_false(Log:should_delete(os.date("%Y%m%d")))
    end)
end)

describe("clean", function()
    it("keep", function()
        f1:touch()
        assert(f1:exists())
        Log.clean(f1)
        assert(f1:exists())
    end)
    
    it("delete", function()
        f2:touch()
        assert(f2:exists())
        Log.clean(f2)
        assert.is_false(f2:exists())
    end)
end)

describe("parse_line", function()
    it("empty", function()
        assert.are.same({}, Log.parse_line(""))
    end)
    
    it("+", function()
        assert.are.same({key = "a", val = "b", date = 1}, Log.parse_line("  a: b", 1))
    end)
end)


describe("record", function()
    it("existing rows deleted", function()
        local row = {date = f1:stem(), key = "key", val = "val"}
        Log:insert(row)
        assert(Log:where(row))
        f1:touch()
        Log.record(f1)
        assert.is_nil(Log:where(row))
    end)
    
    it("inserts new rows", function()
        local row = {date = f1:stem(), key = "key", val = "val"}
        Log:insert(row)
        assert(Log:where(row))

        f1:write({
            "a: b",
            "c: d",
        })
        Log.record(f1)

        assert(Log:where({date = f1:stem(), key = "a", val = "b"}))
        assert(Log:where({date = f1:stem(), key = "c", val = "d"}))
        assert.are.same(2, #Log:get())
    end)
end)
