local Path = require("hl.path")
local List = require("hl.List")

local TextList = require("htl.text.list")

local test_dir = Path.joinpath(Path.tempdir(), "test-dir")
local test_file = Path.joinpath(test_dir, "test-file.md")
local test_hidden_file = Path.joinpath(test_dir, ".test-file.md")

local test_subdir = Path.joinpath(test_dir, "test-subdir")
local test_subfile = Path.joinpath(test_subdir, "test-subfile.md")

before_each(function()
    Path.rmdir(test_dir, true)
end)

after_each(function()
    Path.rmdir(test_dir, true)
end)

describe("Line", function()
    describe(":new", function() 
        it("makes an empty Item", function()
            local item1 = TextList.Line({text = "1"})
            local item2 = TextList.Line({text = "2"})

            assert.equal('1', item1.text)
            assert.equal('2', item2.text)
        end)
    end)

    describe(":tostring: ", function()
        it("works", function()
            local x = TextList.Line({text = 'text', indent = '    '})
            assert.equal(tostring(x), "    text")
        end)
    end)

    describe(":merge: ", function()
        it("Line + Line", function()
            local one = TextList.Line({text = '1'})
            local two = TextList.Line({text = ' 2'})

            assert.equal(tostring(one), '1')

            one:merge(two)

            assert.equal(tostring(one), '1 2')
        end)

        it("Line + ListLine", function()
            local one = TextList.Line({text = '1    ', indent = '    '})
            local two = TextList.ListLine({text = '2', indent = '    '})

            assert.equal(tostring(one), '    1    ')
            assert.equal(tostring(two), '    - 2')

            one:merge(two)

            assert.equal(tostring(one), '    1 2')
        end)
    end)
end)

describe("ListLine", function()
    describe(":new", function() 
        it("makes an empty Item", function()
            local item1 = TextList.ListLine({text = "1"})
            local item2 = TextList.ListLine({text = "2"})

            assert.equal(item1.text, '1')
            assert.equal(item2.text, '2')
        end)
    end)

    describe(":tostring:", function()
        it("basic case", function()
            local item = TextList.ListLine({text = 'text', indent = '    '})

            assert.equal(tostring(item), "    - text")
        end)
    end)

    describe(".get_if_str_is_a:", function()
        it("-", function()
            assert.is_nil(TextList.ListLine.get_if_str_is_a("string", 0))
        end)

        it("+", function()
            assert.are.same(
                TextList.ListLine.get_if_str_is_a("    - string", 0),
                TextList.ListLine({text = "string", indent = "    ", line_number = 0})
            )
        end)
    end)
end)

describe("NumberedListLine", function()
    describe(":new", function() 
        it("makes an empty Item", function()
            assert.equal(TextList.NumberedListLine().number, 1)
        end)
    end)

    describe(":tostring", function()
        it("basic case", function()
            local item = TextList.NumberedListLine({text = 'text', indent = '    '})
            assert.equal(tostring(item), "    1. text")
        end)
    end)

    describe("._get_if_str_is_a", function()
        it("-", function()
            assert.is_nil(TextList.NumberedListLine._get_if_str_is_a("- string", 0))
        end)

        it("+", function()
            assert.are.same(
                TextList.NumberedListLine._get_if_str_is_a("    10. string", 0),
                TextList.NumberedListLine({number = 10, text = "string", indent = "    ", line_number = 0})
            )
        end)
    end)
end)

describe("Parser", function()
    before_each(function()
        parser = TextList.Parser()
    end)

    describe("new", function()
        it("gets default list types", function()
            assert.are.same(Parser.default_types, parser.types)
        end)

        it("accepts added types", function()
            assert(List(TextList.Parser({"question"}).types):contains("question"))
        end)

        it("handles duplicate types", function()
            local default_types = TextList.Parser.default_types
            TextList.Parser.default_types = {"bullet"}
            assert.are.same({"bullet", "question"}, TextList.Parser({"question", "bullet"}).types)
            TextList.Parser.default_types = default_types
        end)
    end)

    describe("parse_line", function()
        it("basic line", function()
            assert.are.same(
                TextList.Line({text="text", line_number = 1}),
                parser:parse_line("text", 1)
            )
        end)

        it("list line", function()
            assert.are.same(
                TextList.ListLine.get_class("bullet")({text="text", line_number = 1}),
                parser:parse_line("- text", 1)
            )
        end)

        it("numbered list line", function()
            assert.are.same(
                TextList.NumberedListLine({text="text", number = 10, line_number = 1}),
                parser:parse_line("10. text", 1)
            )
        end)

        it("handles additional types", function()
            expected = TextList.Line({text="? text", line_number = 1})
            assert.are.same(expected, parser:parse_line("? text", 1))
        
            
            parser = TextList.Parser({"question"})
        
            expected = TextList.ListLine.get_class("question")({text="text", line_number = 1})
            assert.are.same(expected, parser:parse_line("? text", 1))
        end)
    end)

    describe("get instances", function()
        it("basics", function()
            Path.write(test_file, {"- abc", "    - 123"})
            Path.write(test_subfile, {"x", "y", "- beta"})
            local actual = TextList.Parser.get_instances("bullet", test_dir)

            local test_file_short = Path.with_suffix(Path.relative_to(test_file, test_dir), ''):removeprefix('/')
            local test_subfile_short = Path.with_suffix(Path.relative_to(test_subfile, test_dir), ''):removeprefix('/')
            assert.are.same(
                {
                    [test_file_short] = {{line_number = 1, text = 'abc'}, {line_number = 2, text = '123'}},
                    [test_subfile_short] = {{line_number = 3, text = 'beta'}},
                },
                actual
            )
        end)
    end)
end)
