local Path = require("hl.Path")

local Fields = require("htl.notes.field")
local File = require("htl.notes.note.file")

local path = Path.tempdir:join("test-file.md")
local fields = Fields.format({
    "a",
    b = true,
    c = {1, 2, 3},
    d = {type = "list"}
})

local file

before_each(function()
    path:unlink()
    file = File(tostring(path), fields)
    stub(Fields, "format", function(...) return ... end)
end)

after_each(function()
    path:unlink()
    file = nil
    Fields.format:revert()
end)

describe("read", function()
    it("non-existing", function()
        assert.are.same({{}, ""}, file:read())
    end)

    it("existing", function()
        file:write({a = 1}, "test")
        assert.are.same({{a = 1}, "test"}, file:read())
    end)
end)

describe("touch", function()
    it("existing", function()
        Path(file.path):write("hunter")
        file:touch()
        assert.are.same("hunter", Path(file.path):read())
    end)

    it("new", function()
        file:touch({a = 2, d = 3})

        assert.are.same(
            {a = 2, b = true, d = {3}, date = tonumber(os.date("%Y%m%d"))},
            file:get_metadata()
        )
    end)
end)

describe("set_metadata", function()
    it("works", function()
        file:touch({a = 2, d = 3})

        assert.are.same(
            {a = 2, b = true, d = {3}, date = tonumber(os.date("%Y%m%d"))},
            file:get_metadata()
        )

        file:set_metadata({a = 1, b = false, c = 3, d = 'z'})

        assert.are.same(
            {a = 1, b = false, c = 3, d = {'z'}, date = tonumber(os.date("%Y%m%d"))},
            file:get_metadata()
        )
    end)
end)

describe("blurb", function()
    it("has blurb", function()
        file:write({a = 1}, "blurb")

        assert.are.same(
            "blurb",
            file:get_blurb()
        )
    end)

    it("has no blurb", function()
        file:write({a = 1})

        assert.are.same(
            "test file",
            file:get_blurb()
        )
    end)
end)
