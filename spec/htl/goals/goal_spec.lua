local Goal = require("htl.goals.goal")

local todo_sigil = '◻'
local done_sigil = '✓'
local reject_sigil = '⨉'

local text_list_type_to_sigil = {
    todo = todo_sigil,
    done = done_sigil,
    reject = reject_sigil,
}

describe("basic parsing", function()
    it("works", function()
        for text_list_type, sigil in pairs(text_list_type_to_sigil) do
            assert.are.same(
                text_list_type,
                Goal(string.format("%s abc", sigil)).line_type
            )
        end
    end)
end)

describe("completed", function()
    it("+: done", function()
        assert(Goal(string.format("%s abc", done_sigil)):completed())
    end)

    it("-: todo", function()
        assert.falsy(Goal(string.format("%s abc", todo_sigil)):completed())
    end)

    it("-: reject", function()
        assert.falsy(Goal(string.format("%s abc", reject_sigil)):completed())
    end)
end)

describe("open", function()
    it("-: done", function()
        assert.falsy(Goal(string.format("%s abc", done_sigil)):open())
    end)

    it("-: reject", function()
        assert.falsy(Goal(string.format("%s abc", reject_sigil)):open())
    end)

    it("-: todo", function()
        assert(Goal(string.format("%s abc", todo_sigil)):open())
    end)
end)

describe("parse_project", function()
    it("has project", function()
        assert.are.same(
            {str = "a", project = "p"},
            Goal.parse_project({str = "a {p}"})
        )
    end)

    it("no project", function()
        assert.are.same(
            {str = "a"},
            Goal.parse_project({str = "a"})
        )
    end)
end)

describe("format_qualifier", function()
    it("finish", function()
        assert.are.same({finish = true}, Goal.format_qualifier("f"))
    end)

    it("thousand words", function()
        assert.are.same({["thousand words"] = 1.5}, Goal.format_qualifier("1.5kw"))
    end)

    it("words", function()
        assert.are.same({words = 100}, Goal.format_qualifier("100w"))
    end)

    it("hours", function()
        assert.are.same({hours = 1.5}, Goal.format_qualifier("1.5h"))
    end)
end)

describe("parse_qualifier", function()
    it("qualifier", function()
        assert.are.same(
            {str = "a", qualifier = {finish = true}},
            Goal.parse_qualifier({str = "a [f]"})
        )
    end)

    it("no qualifier", function()
        assert.are.same(
            {str = "a {p}"},
            Goal.parse_qualifier({str = "a {p}"})
        )
    end)
end)

describe("parse_scope", function()
    it("scope", function()
        assert.are.same(
            {str = "a", scope = "x:y"},
            Goal.parse_scope({str = "x:y: a"})
        )
    end)

    it("no scope", function()
        assert.are.same(
            {str = "a {p}"},
            Goal.parse_scope({str = "a {p}"})
        )
    end)
end)

describe("parse", function()
    local cases = {
        ['a'] = {object = 'a'},
        ['a {p}'] = {object = 'a', project = 'p'},
        ['a [f]'] = {object = 'a', qualifier = {finish = true}},
        ['s: a'] = {scope = 's', object = 'a'},
        ['s: '] = {scope = 's'},
    }

    for input, expected in pairs(cases) do
        it(input, function()
            assert.are.same(expected, Goal.parse(input))
        end)
    end

end)
