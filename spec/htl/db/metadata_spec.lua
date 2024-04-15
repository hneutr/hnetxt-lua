local HTL = require("htl")

local Taxonomy = require("htl.Taxonomy")

local d1 = HTL.test_dir / "dir-1"
local d2 = HTL.test_dir / "dir-2"

local f1 = d1 / "file-1.md"
local f2 = d2 / "file-2.md"
local f3 = d1 / "file-3.md"
local f4 = d1 / "file-4.md"

local p1 = {title = "test", path = d1, created = "19930120"}
local p2 = {title = "test2", path = d2, created = "19930120"}
local u1
local u2
local u3
local u4
local taxonomy

local M

before_each(function()
    HTL.before_test()

    DB.projects:insert(p1)
    DB.projects:insert(p2)

    f1:touch()
    f2:touch()
    f3:touch()
    f4:touch()

    DB.urls:insert({project = p1.title, path = f1})
    DB.urls:insert({project = p2.title, path = f2})
    DB.urls:insert({project = p1.title, path = f3})
    DB.urls:insert({project = p1.title, path = f4})

    u1 = DB.urls:where({path = f1}).id
    u2 = DB.urls:where({path = f2}).id
    u3 = DB.urls:where({path = f3}).id
    u4 = DB.urls:where({path = f4}).id

    Conf.paths.global_taxonomy_file:write({
        "a:",
        "  b:",
        "    c:",
        "    d:",
        "e:",
        "  f:",
        "g:",
        "  h:",
        "    i:",
        "    j:",
        "  k:",
    })

    taxonomy = Taxonomy()
    
    M = DB.metadata
end)

after_each(function()
    HTL.after_test()
end)

describe("insert_dict", function()
    it("tags/fields", function()
        assert.is_nil(M:where({url = u1}))
        
        M:insert_dict(
            Dict({
                ["@a"] = Dict({metadata = {}, datatype = "primitive"}),
                ["b"] = Dict({metadata = {}, val = "c", datatype = "primitive"}),
                ["d"] = Dict({metadata = {}, val = "123", datatype = "reference"}),
            }),
            u1
        )
        
        assert.is_not.Nil(M:where({key = "@a", url = url}))
        assert.is_not.Nil(M:where({key = "b", url = url, val = "c"}))
        assert.is_not.Nil(M:where({key = "d", url = url, val = "123", datatype = "reference"}))
    end)

    it("nested", function()
        assert.is_nil(M:where({url = u1}))
        
        M:insert_dict(
            Dict({
                a = Dict({
                    datatype = "primitive",
                    metadata = {
                        b = Dict({val = "c", datatype = "primitive"}),
                        ["@x"] = {datatype = "primitive"},
                    },
                }),
                ["@y"] = {datatype = "primitive"}
            }),
            u1
        )

        local root = M:where({key = M.root_key, url = url})

        local y = M:where({key = "@y", url = url})
        assert.is_not.Nil(y)
        assert.are.same(y.parent, root.id)
        assert.is_nil(y.val)
        
        local a = M:where({key = "a", url = url})
        assert.is_not.Nil(a)
        assert.are.same(a.parent, root.id)
        assert.is_nil(y.val)

        assert.is_not.Nil(M:where({key = "@x", url = url, parent = a.id}))
        assert.is_not.Nil(M:where({key = "b", val = "c", url = url, parent = a.id}))
    end)

end)

describe("get_urls", function()
    it("dir", function()
        M:insert({key = "a", url = u1})
        M:insert({key = "b", url = u2})

        assert.are.same(
            {u1},
            M:get_urls({path = d1, include_values = true}):col('url')
        )
    end)
    
    it("conditions", function()
        M:insert({key = "a", url = u1})
        M:insert({key = "b", url = u1})

        assert.are.same(
            {u1, u1},
            M:get_urls({conditions = "a", include_values = true}):col('url')
        )
    end)

    it("reference", function()
        M:insert({key = "a", val = u1, url = u1, datatype = "reference"})
        M:insert({key = "b", val = u2, url = u2, datatype = "reference"})
        M:insert({key = "c", val = u1, url = u3, datatype = "reference"})
        M:insert({key = "d", val = u3, url = u4, datatype = "reference"})

        assert.are.same(
            {u1, u3, u4},
            M:get_urls({reference = u1, include_links = true}):col('url'):sorted()
        )
    end)
end)

describe("construct_taxonomy_key_map", function()
    it("2 children, 1 common key", function()
        assert.are.same(
            {
                a = {"x"},
                b = {},
                c = {"y"},
                d = {"z"},
            },
            M:construct_taxonomy_key_map(
                {
                    c = Set({"x", "y"}),
                    d = Set({"x", "z"}),
                },
                taxonomy
            )
        )
    end)

    it("child + parent, 1 common key", function()
        assert.are.same(
            {
                a = {"x"},
                b = {"y"},
                c = {"z"},
            },
            M:construct_taxonomy_key_map(
                {
                    b = Set({"x", "y"}),
                    c = Set({"x", "z"}),
                },
                taxonomy
            )
        )
    end)

    it("checks upward", function()
        assert.are.same(
            {
                g = {"g", "h"},
                h = {},
                i = {"i"},
                j = {"j"},
                k = {"k"},
            },
            M:construct_taxonomy_key_map(
                {
                    i = Set({"g", "h", "i"}),
                    j = Set({"g", "h", "j"}),
                    k = Set({"g", "k"})
                },
                taxonomy
            )
        )
    end)
end)
