local Metadata = require("hd.metadata")

describe("str_is_a", function()
    it("+: no uuid", function()
        assert(Metadata.str_is_a("![a](b):"))
    end)

    it("-: no uuid", function()
        assert.falsy(Metadata.str_is_a("> [a](b):"))
    end)

    it("+: uuid", function()
        assert(Metadata.str_is_a("![a](b):"), 'b')
    end)

    it("-: uuid", function()
        assert.falsy(Metadata.str_is_a("![a](b):", 'c'))
    end)
end)

describe("from_lines", function()
    it("works", function()
        assert.are.same(
            Metadata({
                label = "a",
                uuid = "b",
                fields = {
                    c = "d",
                    e = {label = "f", location = "g"},
                },
            }),
            Metadata.from_lines({
                "![a](b):",
                "  c: d",
                "  e: [f](g)",
            })
        )
    end)
end)

describe("parse_line", function()
    it("key-val", function()
        assert.are.same(
            {["is a"] = "test"},
            Metadata.parse_line("  is a: test")
        )
    end)

    it("key-val[link]", function()
        assert.are.same(
            {of = {label = "a", location = "b"}},
            Metadata.parse_line("  of: [a](b)")
        )
    end)
end)

describe("search_path", function()
    it("has all components", function()
        assert.are.same(
            "/x.y:z",
            Metadata({label = 'z', fields = {of = 'x', ['is a'] = 'y'}}):search_path()
        )
    end)

    it("links", function()
        assert.are.same(
            "/x.y:z",
            Metadata({label = 'z', fields = {of = {location = 'abc', label = "x"}, ['is a'] = 'y'}}):search_path()
        )
    end)
    it("missing components", function()
        assert.are.same(
            ".y:z",
            Metadata({label = 'z', fields = {['is a'] = 'y'}}):search_path()
        )
    end)
end)
