local htl = require("htl")

local d1 = htl.test_dir / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file-1.md"
local f2 = d1 / "file-2.md"
local u1
local u2

before_each(function()
    htl.before_test()
    M = DB.Taxonomy

    Conf.paths.global_taxonomy_file:touch()
    DB.projects:insert({title = "global", path = Conf.paths.global_taxonomy_file:parent()})
    DB.urls:insert({path = Conf.paths.global_taxonomy_file})

    DB.projects:insert(p1)
    DB.urls:insert({path = f1})
    DB.urls:insert({path = f2})

    u1 = DB.urls:where({path = f1}).id
    u2 = DB.urls:where({path = f2}).id
end)

after_each(htl.after_test)

describe("insert", function()
    it("works", function()
        M:insert({
            url = u1,
            lineage = {u2, u1},
            type = "instance",
        })

        assert.are.same(
            {
                id = 1,
                url = u1,
                lineage = {u2, u1},
                type = "instance",
            },
            M:__get({where = {url = u1}})[1]
        )
    end)

    it("empty lineage", function()
        M:insert({
            url = u1,
            lineage = {},
            type = "instance",
        })

        assert.are.same(
            {
                id = 1,
                url = u1,
                lineage = {},
                type = "instance",
            },
            M:__get({where = {url = u1}})[1]
        )
    end)
end)
