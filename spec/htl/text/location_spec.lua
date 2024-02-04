local Path = require("hl.Path")
local Location = require("htl.text.location")
local Link = require("htl.text.link")
local db = require("htl.db")
local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

local d1 = Path.tempdir:join("dir-1")
local sd1 = d1:join("subdir-1")

local f1 = d1:join("file-1.md")
local f2 = d1:join("file-2.md")
local f3 = sd1:join("file-3.md")

local p1 = {title = "test", path = d1, created = "19930120"}

before_each(function()
    db.before_test()

    d1:rmdir(true)
    projects:insert(p1)
end)

after_each(function()
    db.after_test()
end)

describe("__tostring", function() 
    it("+", function()
        local one = Location({path = 'a', label = 'b'})
        local two = Location({path = 'c'})
        assert.equals("a:b", tostring(one))
        assert.equals("c", tostring(two))
    end)
end)

describe("str_has_label", function()
    it("+", function()
        assert(Location.str_has_label("a:b"))
    end)

    it("+: multiple ':'", function()
        assert(Location.str_has_label("a:b: c"))
    end)

    it("-", function()
        assert.falsy(Location.str_has_label("a/b"))
    end)
end)

describe("from_str", function()
    it("no text", function()
        assert.are.same(
            Location({path = "a/b"}),
            Location.from_str("a/b")
        )
    end)

    it("text", function()
        assert.are.same(
            Location({path = "a/b", label = "c"}),
            Location.from_str("a/b:c")
        )
    end)

    it("multiple ':'", function()
        assert.are.same(
            Location({path = "a/b", label = "c: d"}),
            Location.from_str("a/b:c: d")
        )
    end)

    it("relative_to", function()
        assert.are.same(
            Location({path = "/a/b/c", label = "d"}),
            Location.from_str("b/c:d", {relative_to = "/a"})
        )
    end)
end)

describe("get_file_locations", function()
    it("works", function()
        urls:insert({path = f1})
        urls:insert({path = f2})

        assert.are.same(
            {f1, f2},
            Location.get_file_locations(d1):sorted(function(a, b)
                return tostring(a) < tostring(b)
            end)
        )
    end)
end)

describe("get_mark_locations", function() 
    it("1 mark", function()
        f1:write(tostring(Link({label = 'a'})))
        
        assert.are.same(
            {Path(Location({path = f1, label = 'a'}))},
            Location.get_mark_locations(d1)
        )
    end)

    it("multiple marks, 1 file", function()
        local mark_a = Link({label = 'a'})
        local mark_b = Link({label = 'b'})
        f1:write({tostring(mark_a), "not a mark", tostring(mark_b)})
        assert.are.same(
            {
                Path(Location({path = f1, label = 'a'})),
                Path(Location({path = f1, label = 'b'}))
            },
            Location.get_mark_locations(d1)
        )
    end)

    it("multiple marks, multiple files", function()
        local mark_a = Link({label = 'a'})
        local mark_b = Link({label = 'b'})
        f1:write({tostring(mark_a), "not a mark"})
        f3:write({"not a mark", tostring(mark_b)})

        assert.are.same(
            {
                Path(Location({path = f1, label = 'a'})),
                Path(Location({path = f3, label = 'b'}))
            },
            Location.get_mark_locations(d1):sorted(function(a, b)
                return tostring(a) < tostring(b)
            end)
        )
    end)
end)
