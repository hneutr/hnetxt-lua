local Dict = require("hl.Dict")
local UnitTest = require("hl.UnitTest")

string = require('hl.string')

local M = string

describe("split", function()
    UnitTest.suite(function(input) return M.split(unpack(input)) end, {
        ["no match"] = {input = {"a"}, expected = {"a"}},
        ["starts with sep"] = {input = {" a"}, expected = {"a"}},
        ["ends with sep"] = {input = {"a "}, expected = {"a"}},
        ["starts with defined sep"] = {input = {"\na", "\n"}, expected = {"", "a"}},
        ["ends with defined sep"] = {input = {"a\n", "\n"}, expected = {"a", ""}},
        ["once"] = {input = {"a b"}, expected = {"a", "b"}},
        ["twice"] = {input = {"a b c"}, expected = {"a", "b", "c"}},
        ["different sep"] = {input = {"a-b-c", "-"}, expected = {"a", "b", "c"}},
        ["maxsplit"] = {input = {"a-b-c", "-", 1}, expected = {"a", "b-c"}},
        ["long sep"] = {input = {"a--b--c", "--"}, expected = {"a", "b", "c"}},
        ["consecutive splits, sep defined"] = {input = {"\n\n\n", "\n"}, expected = {"", "", "", ""}},
        ["consecutive splits, sep undefined"] = {input = {"    "}, expected = {}},
    })
end)

describe("rsplit", function()
    UnitTest.suite(function(input) return M.rsplit(unpack(input)) end, {
        ["base"] = {input = {"a-b-c", "-", 1}, expected = {"a-b", "c"}},
        ["long sep"] = {input = {"a--b--c", "--", 1}, expected = {"a--b", "c"}},
    })
end)

describe("splitlines", function()
    UnitTest.suite(M.splitlines, {
        ['base case'] = {input = "a\nb\nc", expected = {"a", "b", "c"}},
        ['empty line between'] = {input = "a\n\n\nb", expected = {"a", "", "", "b"}},
        ['newline starts'] = {input = "\n\na\nb", expected = {"", "", "a", "b"}},
        ['newline ends'] = {input = "a\nb\n\n", expected = {"a", "b", "", ""}},
        ['multicase'] = {input = "\n\na\n\n\nb\nc\n\n", expected = {"", "", "a", "", "", "b", "c", "", ""}},
    })
end)

describe("startswith", function()
    UnitTest.suite(function(input) return M.startswith(unpack(input)) end, {
        ['+'] = {input = {"abc", "a"}, expected = true},
        ["-"] = {input = {"abc", "b"}, expected = false},
        ["escaped, not plain"] = {input = {[[%sa]], [[%s]], false}, expected = false},
        ["escaped, plain"] = {input = {[[%sa]], [[%s]]}, expected = true},
    })
end)

describe("endswith", function()
    UnitTest.suite(function(input) return M.endswith(unpack(input)) end, {
        ['+'] = {input = {"abc", "c"}, expected = true},
        ["multichar ending"] = {input = {"abc", "bc"}, expected = true},
        ['-'] = {input = {"abc", "b"}, expected = false},
        ["escaped, plain"] = {input = {[[a%s]], [[%s]]}, expected = true},
        ["escaped, not plain"] = {input = {[[as%]], [[s%]], false}, expected = false},
    })
end)

describe("join", function()
    UnitTest.suite(function(input) return M.join(unpack(input)) end, {
        ["+"] = {input = {", ", {"a", "b", "c"}}, expected = "a, b, c"},
    })
end)

describe("lstrip", function()
    UnitTest.suite(function(input) return M.lstrip(unpack(input)) end, {
        ["whitespace"] = {input = {" a "}, expected = "a "},
        ["multiple chars"] = {input = {"! a ", {"%s", "!"}}, expected = "a "},
    })
end)

describe("rstrip", function()
    UnitTest.suite(function(input) return M.rstrip(unpack(input)) end, {
        ["whitespace"] = {input = {" a "}, expected = " a"},
        ["multiple chars"] = {input = {"! a !", {"%s", "!"}}, expected = "! a"},
    })
end)

describe("strip", function()
    UnitTest.suite(function(input) return M.strip(unpack(input)) end, {
        ["whitespace"] = {input = {" a "}, expected = "a"},
        ["multiple chars"] = {input = {"! a !", {"%s", "!"}}, expected = "a"},
    })
end)

describe("partition", function()
    UnitTest.suite(function(input) return M.partition(unpack(input)) end, {
        ["+"] = {input = {"abc 1 xyz", "1"}, expected = {"abc ", "1", " xyz"}},
        ["sep at start"] = {input = {"1 abc", "1"}, expected = {"1", " abc"}},
        ["no sep"] = {input = {"abc xyz", "1"}, expected = {"abc xyz"}},
        ["multiple partitions"] = {input = {"a 1 b 1", "1"}, expected = {"a ", "1", " b ", "1"}},
        ["maxpartitions"] = {
            input = {"a 1 b 1 c 1", "1", 2},
            expected = {"a ", "1", " b ", "1", " c 1"}
        },
        ["multiple seps"] = {
            input = {"a 1 b 2 c 1 d", {"2", "1"}},
            expected = {"a ", "1", " b ", "2", " c ", "1", " d"},
        },
    })
end)

describe("rpartition", function()
    UnitTest.suite(function(input) return M.rpartition(unpack(input)) end, {
        ["+"] = {input = {"a 1 1 b", "1", 1}, expected = {"a 1 ", "1", " b"}},
        ["long sep"] = {input = {"a x1 b 1x c", "1x"}, expected = {"a x1 b ", "1x", " c"}},
    })
end)

describe("removeprefix", function()
    it('+', function()
        assert.are.same({"abcz", true}, {M.removeprefix("zabcz", "z")})
    end)

    it('-', function()
        assert.are.same({"abc", false}, {M.removeprefix("abc", "z")})
    end)

    it('multichar prefix', function()
        assert.are.same("abczzzz", M.removeprefix("zzzabczzzz", "zzz"))
    end)
end)

describe("removesuffix", function()
    it('+', function()
        assert.are.same({"zabc", true}, {M.removesuffix("zabcz", "z")})
    end)

    it('-', function()
        assert.are.same({"zabc", false}, {M.removesuffix("zabc", "z")})
    end)

    it('multichar prefix', function()
        assert.are.same("zzzabc", M.removesuffix("zzzabczzz", "zzz"))
    end)
end)

describe("rfind", function()
    it("does", function()
        assert.are.same(6, M.rfind("a bc bc d", "bc"))
    end)
end)

describe("center", function()
    it("does evenly", function()
        assert.are.same("    ab    ", M.center("ab", 10))
    end)

    it("does oddly", function()
        assert.are.same("     a    ", M.center("a", 10))
    end)

    it("long", function()
        assert.are.same("a", M.center("a", 1))
    end)
end)

describe("escape", function()
    it("escapes", function()
        for _, char in ipairs({"^", "$", "(", ")", "%", ".", "[", "]", "*", "+", "-", "?"}) do
            assert.are.same("%" .. char, M.escape(char))
        end
    end)

    it("multiple", function()
        assert.are.same("%-%*", M.escape("-*"))
        assert.are.same(" %-> ", M.escape(" -> "))
    end)
end)

describe("keys", function()
    it("+", function()
        local actual = Dict.keys({a = 1, b = 2, c = 3})
        table.sort(actual)
        assert.are.same({'a', 'b', 'c'}, actual)
    end)
end)

describe("rpad", function()
    it("works", function()
        assert.are.same("1 ", M.rpad("1", 2))
    end)

    it("works", function()
        assert.are.same("122", M.rpad("1", 3, "2"))
    end)
end)

describe("lpad", function()
    it("works", function()
        assert.are.same(" 1", M.lpad("1", 2))
    end)

    it("works", function()
        assert.are.same("221", M.lpad("1", 3, "2"))
    end)
end)

describe("bisect", function()
    UnitTest.suite(function(input) return M.bisect(unpack(input)) end, {
        ["index < 1"] = {input = {"abc", -1}, expected = {"", "abc"}},
        ["index = 1"] = {input = {"abc", 1}, expected = {"a", "bc"}},
        ["index > #string"] = {input = {"abc", 4}, expected = {"abc", ""}},
        ["index == #string"] = {input = {"abc", 3}, expected = {"abc", ""}},
    }, {pack_output = true})
end)
