local stub = require('luassert.stub')
local List = require("hl.List")
local Path = require("hl.Path")

local metadata = require("htl.db.metadata")
local Taxonomy = require("htl.metadata").Taxonomy

local db = require("htl.db")
local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

local d1 = Path.tempdir:join("dir-1")
local d2 = Path.tempdir:join("dir-2")

local f1 = d1:join("file-1.md")
local f2 = d2:join("file-2.md")
local f3 = d1:join("file-3.md")
local f4 = d1:join("file-4.md")

local p1 = {title = "test", path = d1, created = "19930120"}
local p2 = {title = "test2", path = d2, created = "19930120"}
local u1
local u2
local u3
local u4

before_each(function()
    db.before_test()

    d1:rmdir()
    d2:rmdir()
    projects:insert(p1)
    projects:insert(p2)
    urls:insert({project = p1.title, path = f1})
    urls:insert({project = p2.title, path = f2})
    urls:insert({project = p1.title, path = f3})
    urls:insert({project = p1.title, path = f4})

    u1 = urls:where({path = f1}).id
    u2 = urls:where({path = f2}).id
    u3 = urls:where({path = f3}).id
    u4 = urls:where({path = f4}).id

    Taxonomy.global_taxonomy = Dict({
        a = {
            b = {
                c = {},
                d = {},
            },
        },
        e = {
            f = {}
        },
        g = {
            h = {
                i = {},
                j = {},
            },
            k = {},
        },
    })
end)

after_each(function()
    db.after_test()
    Taxonomy.global_taxonomy = Dict(Taxonomy.config.global_taxonomy)
end)

describe("parse", function()
    it("non-nested", function()
        assert.are.same(
            {
                a = {val = "b", metadata = {}},
                c = {val = "d", metadata = {}},
                ["@x"] = {metadata = {}},
                ["@y"] = {metadata = {}},
            },
            metadata:parse(List({
                "a: b",
                "c: d",
                "@x",
                "@y",
            }))
        )
    end)

    it("nested", function()
        assert.are.same(
            {
                a = {
                    val = "b",
                    metadata = {
                        c = {val = "d", metadata = {}},
                        ["@x"] = {metadata = {}},
                    }
                },
                e = {val = "f", metadata = {}},
                ["@y"] = {metadata = {}}
            },
            metadata:parse(List({
                "a: b",
                "  c: d",
                "  @x",
                "e: f",
                "@y",
            }))
        )
    end)
end)

describe("parse_val", function()
    it("no val", function()
        local val, datatype = metadata:parse_val()
        assert.are.same({nil, "primitive"}, {val, datatype})
    end)

    it("non-link val", function()
        local val, datatype = metadata:parse_val("abc")
        assert.are.same({"abc", "primitive"}, {val, datatype})
    end)

    it("link val", function()
        local val, datatype = metadata:parse_val("[abc](123)")
        assert.are.same({"123", "reference"}, {val, datatype})
    end)

end)

describe("insert_dict", function()
    it("tags/fields", function()
        assert.is_nil(metadata:where({url = u1}))
        
        metadata:insert_dict(
            Dict({
                ["@a"] = Dict({metadata = {}}),
                ["b"] = Dict({metadata = {}, val = "c"}),
                ["d"] = Dict({metadata = {}, val = "[x](123)"}),
            }),
            u1
        )

        assert.is_not.Nil(metadata:where({key = "@a", url = url}))
        assert.is_not.Nil(metadata:where({key = "b", url = url, val = "c"}))
        assert.is_not.Nil(metadata:where({key = "d", url = url, val = "123", datatype = "reference"}))
    end)

    it("nested", function()
        assert.is_nil(metadata:where({url = u1}))
        
        metadata:insert_dict(
            Dict({
                a = Dict({
                    metadata = {
                        b = Dict({val = "c"}),
                        ["@x"] = {},
                    },
                }),
                ["@y"] = {}
            }),
            u1
        )

        local root = metadata:where({key = metadata.root_key, url = url})

        local y = metadata:where({key = "@y", url = url})
        assert.is_not.Nil(y)
        assert.are.same(y.parent, root.id)
        assert.is_nil(y.val)
        
        local a = metadata:where({key = "a", url = url})
        assert.is_not.Nil(a)
        assert.are.same(a.parent, root.id)
        assert.is_nil(y.val)

        assert.is_not.Nil(metadata:where({key = "@x", url = url, parent = a.id}))
        assert.is_not.Nil(metadata:where({key = "b", val = "c", url = url, parent = a.id}))
    end)
end)

describe("parse_condition", function()
    it("startswith: +", function()
        assert.is_true(metadata.parse_condition("@a").startswith)
    end)

    it("startswith: -", function()
        assert.is_false(metadata.parse_condition("a").startswith)
    end)

    it("is_exclusion: +", function()
        local condition = metadata.parse_condition("@a-")
        assert.is_true(condition.is_exclusion)
        assert.are.same("@a", condition.key)
    end)

    it("is_exclusion: +", function()
        local condition = metadata.parse_condition("@a")
        assert.is_false(condition.is_exclusion)
    end)

    it("no vals", function()
        local condition = metadata.parse_condition("a")
        assert.is_nil(condition.vals)
    end)

    it("1 val", function()
        local condition = metadata.parse_condition("a:x")
        assert.are.same("a", condition.key)
        assert.are.same({"x"}, condition.vals)
    end)

    it("multiple vals", function()
        local condition = metadata.parse_condition("a:x|y")
        assert.are.same("a", condition.key)
        assert.are.same({"x", "y"}, condition.vals)
    end)

    it("is_a", function()
        local condition = metadata.parse_condition("is a: a|e")
        assert.are.same({"a", "b", "c", "d", "e", "f"}, condition.vals:sorted())
    end)
end)

describe("check_condition", function()
    it("condition.key: +", function()
        assert.is_true(metadata.check_condition({key = "a"}, {key = "a"}))
    end)

    it("condition.key: -", function()
        assert.is_false(metadata.check_condition({key = "a"}, {key = "b"}))
    end)

    it("condition.startswith = true: +", function()
        assert.is_true(metadata.check_condition({key = "abc"}, {key = "a", startswith = true}))
    end)

    it("condition.startswith = true: -", function()
        assert.is_false(metadata.check_condition({key = "abc"}, {key = "b", startswith = true}))
    end)

    it("condition.vals = nil, val = nil: true", function()
        assert.is_true(metadata.check_condition({key = "a"}, {key = "a"}))
    end)

    it("condition.vals exists, val = nil: -", function()
        assert.is_false(metadata.check_condition({key = "a"}, {key = "a", vals = List({"x"})}))
    end)

    it("condition.vals exists, val = mismatch: -", function()
        assert.is_false(metadata.check_condition({key = "a", val = "y"}, {key = "a", vals = List({"x"})}))
    end)

    it("condition.vals exists, val = match: +", function()
        assert.is_true(metadata.check_condition({key = "a", val = "y"}, {key = "a", vals = List({"x", "y"})}))
    end)

    it("condition.is_exclusion = true: -", function()
        assert.is_false(metadata.check_condition({key = "a"}, {key = "a", is_exclusion = true}))
    end)

    it("condition.is_exclusion = true: +", function()
        assert.is_true(metadata.check_condition({key = "a"}, {key = "b", is_exclusion = true}))
    end)
end)

describe("get_urls", function()
    it("dir", function()
        metadata:insert({key = "a", url = u1})
        metadata:insert({key = "b", url = u2})

        assert.are.same(
            {u1},
            metadata:get_urls({dir = d1})
        )
    end)
    
    it("conditions", function()
        metadata:insert({key = "a", url = u1})
        metadata:insert({key = "b", url = u1})

        assert.are.same(
            {u1},
            metadata:get_urls({conditions = "a"})
        )
    end)

    it("reference", function()
        metadata:insert({key = "a", val = u1, url = u1, datatype = "reference"})
        metadata:insert({key = "b", val = u2, url = u2, datatype = "reference"})
        metadata:insert({key = "c", val = u1, url = u3, datatype = "reference"})
        metadata:insert({key = "d", val = u3, url = u4, datatype = "reference"})

        assert.are.same(
            {u1, u3, u4},
            metadata:get_urls({reference = u1}):sorted()
        )
    end)
end)

describe("get_subkeys_by_val", function()
    it("val = nil: agnostic", function()
        assert.are.same(
            {__agnostic = {"c"}},
            metadata:get_subkeys_by_val({
                {key = "c", parent_val = nil},
                {key = "c", parent_val = "x"},
            })
        )
    end)

    it("> 1 val: agnostic", function()
        assert.are.same(
            {__agnostic = {"c"}},
            metadata:get_subkeys_by_val({
                {key = "c", parent_val = "x"},
                {key = "c", parent_val = "y"},
            })
        )
    end)

    it("1 val: specific", function()
        assert.are.same(
            {x = {"c"}},
            metadata:get_subkeys_by_val({
                {key = "c", parent_val = "x"},
                {key = "c", parent_val = "x"},
            })
        )
    end)

    it("2 keys, same val", function()
        assert.are.same(
            {x = {"a", "b"}},
            metadata:get_subkeys_by_val({
                {key = "a", parent_val = "x"},
                {key = "b", parent_val = "x"},
            })
        )
    end)
end)

describe("construct_taxonomy_key_map", function()
    it("2 children, 1 common key", function()
        assert.are.same(
            {
                b = {"x"},
                c = {"y"},
                d = {"z"},
            },
            metadata:construct_taxonomy_key_map({
                c = Set({"x", "y"}),
                d = Set({"x", "z"}),
            })
        )
    end)

    it("child + parent, 1 common key", function()
        assert.are.same(
            {
                b = {"x", "y"},
                c = {"z"},
            },
            metadata:construct_taxonomy_key_map({
                b = Set({"x", "y"}),
                c = Set({"x", "z"}),
            })
        )
    end)

    it("checks upward", function()
        assert.are.same(
            {
                g = {"g"},
                h = {"h"},
                i = {"i"},
                j = {"j"},
                k = {"k"},
            },
            metadata:construct_taxonomy_key_map({
                i = Set({"g", "h", "i"}),
                j = Set({"g", "h", "j"}),
                k = Set({"g", "k"})
            })
        )
    end)
end)


describe("get_print_lines", function()
    it("probably doesn't work", function()
        metadata:insert_dict(
            metadata:parse(
                List({
                    "a: b",
                    "  @x",
                    "  @y",
                    "w: v",
                })
            ),
            u1
        )

        metadata:insert_dict(
            metadata:parse(
                List({
                    "a: c",
                    "  @x",
                    "  @z",
                    "  i: k",
                    "w: v",
                    "date: 1",
                })
            ),
            u2
        )

        metadata:insert_dict(
            metadata:parse(
                List({
                    "is a: b",
                    "  @x",
                    "w: v",
                    "@t",
                })
            ),
            u3
        )

        local o = metadata.get_dict({u1, u2, u3})
        print(1)
        print(o)
        print(1)
    end)
end)

