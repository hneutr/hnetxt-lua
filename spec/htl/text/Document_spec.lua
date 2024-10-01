require("htl")

local Header = require("htl.text.Header")

local M = require("htl.text.Document")

describe("filter_lines", function()
    it("stops excluding", function()
        assert.are.same(
            List({
                Header("b", 1),
                "line",
            }):transform(tostring),
            M:filter_lines(List({
                Header("{a}", 1),
                Header("b", 1),
                "line",
            }):transform(tostring))
        )
    end)

    it("excludes sublines", function()
        assert.are.same(
            List({
                Header("c", 1),
                "line",
            }):transform(tostring),
            M:filter_lines(List({
                Header("{a}", 1),
                "line",
                Header("b", 2),
                Header("c", 1),
                "line",
            }):transform(tostring))
        )
    end)

    it("ends document", function()
        assert.are.same(
            {
                "a",
                "b",
            },
            M:filter_lines(List({
                "a",
                "b",
                Conf.text.end_document,
                "c",
            }))
        )
    end)
end)
