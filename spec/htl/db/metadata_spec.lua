local stub = require('luassert.stub')
local List = require("hl.List")
local Path = require("hl.Path")

local Config = require("htl.Config")

local db = require("htl.db")
local projects = require("htl.db.projects")
local Urls = require("htl.db.urls")

local metadata = require("htl.db.metadata")
local Taxonomy = require("htl.metadata.Taxonomy")

local d1 = Config.test_root:join("dir-1")
local d2 = Config.test_root:join("dir-2")

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
local taxonomy

before_each(function()
    db.before_test()

    projects:insert(p1)
    projects:insert(p2)
    f1:touch()
    f2:touch()
    f3:touch()
    f4:touch()

    Urls:insert({project = p1.title, path = f1})
    Urls:insert({project = p2.title, path = f2})
    Urls:insert({project = p1.title, path = f3})
    Urls:insert({project = p1.title, path = f4})

    u1 = Urls:where({path = f1}).id
    u2 = Urls:where({path = f2}).id
    u3 = Urls:where({path = f3}).id
    u4 = Urls:where({path = f4}).id

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
end)

after_each(function()
    db.after_test()
end)

describe("insert_dict", function()
    it("tags/fields", function()
        assert.is_nil(metadata:where({url = u1}))
        
        metadata:insert_dict(
            Dict({
                ["@a"] = Dict({metadata = {}, datatype = "primitive"}),
                ["b"] = Dict({metadata = {}, val = "c", datatype = "primitive"}),
                ["d"] = Dict({metadata = {}, val = "123", datatype = "reference"}),
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

describe("insert", function()
    it("url delete", function()
        local row = {
            key = 'key',
            val = 'val',
            url = u1,
            datatype = 'reference',
        }

        assert.are.same(0, #metadata:get())
        metadata:insert(row)
        assert.are.same(1, #metadata:get())
        Urls:remove({id = u1})
        assert.are.same(0, #metadata:get())
    end)
end)

describe("get_urls", function()
    it("dir", function()
        metadata:insert({key = "a", url = u1})
        metadata:insert({key = "b", url = u2})

        assert.are.same(
            {u1},
            metadata:get_urls({path = d1, include_values = true}):col('url')
        )
    end)
    
    it("conditions", function()
        metadata:insert({key = "a", url = u1})
        metadata:insert({key = "b", url = u1})

        assert.are.same(
            {u1, u1},
            metadata:get_urls({conditions = "a", include_values = true}):col('url')
        )
    end)

    it("reference", function()
        metadata:insert({key = "a", val = u1, url = u1, datatype = "reference"})
        metadata:insert({key = "b", val = u2, url = u2, datatype = "reference"})
        metadata:insert({key = "c", val = u1, url = u3, datatype = "reference"})
        metadata:insert({key = "d", val = u3, url = u4, datatype = "reference"})

        assert.are.same(
            {u1, u3, u4},
            metadata:get_urls({reference = u1, include_links = true}):col('url'):sorted()
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
            metadata:construct_taxonomy_key_map(
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
            metadata:construct_taxonomy_key_map(
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
            metadata:construct_taxonomy_key_map(
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
