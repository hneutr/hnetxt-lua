require("htl")

local M = require("htl.text.Heading")

describe("Meta", function()
    local M = M.Meta

    -- describe("init_conf", function()
    --     it("works", function()
    --         print(inspect(M.conf))
    --     end)
    -- end)

    describe("parse", function()
        it("empty string", function()
            local text, meta = M.parse("")
            assert.equal(text, "")
        end)

        it("no meta", function()
            local text, meta = M.parse("text ")
            assert.equal(text, "text ")
        end)

        it("meta", function()
            local text, meta = M.parse("text [][*]")
            assert.equal(text, "text")
            assert.same(meta.vals, Set("*"))
            assert.same(meta.groups, Set({"change"}))
        end)

        it("multiple item meta", function()
            local text, meta = M.parse("text [][*?]")
            assert.equal(text, "text")
            assert.same(meta.vals, Set({"*", "?"}))
            assert.same(meta.groups, Set({"change", "create"}))
        end)

        it("hide", function()
            local text, meta = M.parse("text [][*?o]")
            assert.equal(text, "text")
            assert.same(meta.vals, Set({"*", "?", "o"}))
            assert.same(meta.groups, Set({"change", "create", "hidden"}))
            assert(meta.hide)
        end)
    end)

    describe("filter", function()
        it("passes", function()
            local meta = M(List({"*"}))
            assert(meta:filter(Set({"change"})))
        end)

        it("passes: item superset", function()
            local meta = M(List({"*", "?"}))
            assert(meta:filter(Set({"change"})))
        end)

        it("passes: item subset", function()
            local meta = M(List({"?"}))
            assert(meta:filter(Set({"change", "create"})))
        end)

        it("passes: filter empty set", function()
            local meta = M(List({"*"}))
            assert(meta:filter(Set()))
        end)

        it("fails", function()
            local meta = M(List({"*"}))
            assert(not meta:filter(Set({"create"})))
        end)

    end)
end)
