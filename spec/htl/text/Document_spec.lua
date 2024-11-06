require("htl")

local Heading = require("htl.text.Heading")

local M = require("htl.text.Document")

describe("filter_lines", function()
    it("stops excluding", function()
        assert.are.same(
            List({
                Heading("b", 1),
                "line",
            }):transform(tostring),
            M:filter_lines(List({
                Heading("a [][o]", 1),
                Heading("b", 1),
                "line",
            }):transform(tostring))
        )
    end)

    it("excludes sublines", function()
        assert.are.same(
            List({
                Heading("c", 1),
                "line",
            }):transform(tostring),
            M:filter_lines(List({
                Heading("a [][o]", 1),
                "line",
                Heading("b", 2),
                Heading("c", 1),
                "line",
            }):transform(tostring))
        )
    end)

    it("stops excluding after same level header", function()
        assert.are.same(
            List({
                "# ",
                "b line",
            }),
            M:filter_lines(List({
                "# a [][o]",
                "# ",
                "b line",
            }))
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
