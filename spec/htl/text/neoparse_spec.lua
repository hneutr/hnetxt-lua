local List = require("hl.List")

local Parser = require("htl.text.neoparse")

local Divider = require("htl.text.neodivider")
local Header = require("htl.text.neoheader")
local TextList = require("htl.text.list")

local parser

--[[
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
┣ hello
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
┠ what's up
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
┃ small
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸

╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸

╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸

╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
--]]

before_each(function()
    parser = Parser()
end)

describe("get_fold_levels", function()
    it("simple case", function()
        assert.are.same(
            {0, 0, 0, 3, 4, 3},
            parser:get_fold_levels(List.from(
                Header({size = 'large'}):get_lines(),
                {"a", "  b", "c"}
            ))
        )
    end)

    it("multiple headers", function()
        assert.are.same(
            {0, 0, 0, 3, 1, 1, 1, 1, 3, 3},
            parser:get_fold_levels(List.from(
                Header({size = 'large'}):get_lines(),
                {"a", ""},
                Header({size = 'medium'}):get_lines(),
                {"b", ""}
            ))
        )
    end)
end)












-- local Path = require("hl.Path")
-- local List = require("hl.List")
-- local Parser = require("htl.parse")
-- local Fold = require("htl.parse.fold")
-- local Header = require("htl.text.header")
-- local Divider = require("htl.text.divider")
-- local Location = require("htl.text.location")

-- local test_file_path = Path.tempdir:join("test-file.md")
-- local other_test_file_path = Path.tempdir:join("test-file-2.md")

-- describe("parse_line_levels", function()
--     local parser = Parser()
--     before_each(function()
--         stub(Fold, "get_line_levels")
--     end)

--     after_each(function()
--         Fold.get_line_levels:revert()
--     end)

--     it("simple", function()
--         assert.are.same(
--             {
--                 [0] = {{1, 2}, {3, 4}},
--                 [1] = {{2}, {4}},
--             },
--             parser:parse_line_levels({line_levels = {0, 1, 0, 1}})
--         )
--     end)

--     it("more complex", function()
--         assert.are.same(
--             {
--                 [0] = {{1, 2, 3, 4, 5, 6, 7}},
--                 [1] = {{2, 3, 4}, {5, 6, 7}},
--                 [2] = {{3, 4}},
--                 [3] = {{6, 7}},
--             },
--             parser:parse_line_levels({line_levels = {0, 1, 2, 2, 1, 3, 3}})
--         )
--     end)

--     it("no fold levels", function()
--         assert.are.same(
--             {{1, 2}, {2}, {3, 4}, {4}},
--             parser:parse_line_levels({line_levels = ({0, 1, 0, 1}), by_fold_level = false})
--         )
--     end)

-- end)

-- describe("remove_initial_mark", function()
--     it("basic mark", function()
--         assert.are.same({"a", "", "b"}, Parser():remove_initial_mark("a", {"[a]()", "a", "", "b"}))
--     end)

--     it("header mark", function()
--         local lines = List.from(tostring(Header({content = "[a]()"})), {"b", "c", "d"})
--         assert.are.same({"", "b", "c", "d"}, Parser():remove_initial_mark("a", lines))
--     end)
-- end)

-- describe("get_mark_content_line_index", function()
--     it("no mark", function()
--         local args = {mark_label = "x", lines = {"a", "", "[a]()"}}
--         assert.are.same(nil, Parser():get_mark_content_line_index(args))
--     end)

--     it("not in header", function()
--         local args = {mark_label = "a", lines = {"a", "", "[a]()"}}
--         assert.are.same(3, Parser():get_mark_content_line_index(args))
--     end)

--     it("in header: start", function()
--         local args = {mark_label = "a", lines = tostring(Header({content = "[a]()"})), index_type="start"}
--         assert.are.same(1, Parser():get_mark_content_line_index(args))
--     end)

--     it("in header: content", function()
--         local args = {mark_label = "a", lines = tostring(Header({content = "[a]()"})), index_type="content"}
--         assert.are.same(2, Parser():get_mark_content_line_index(args))
--     end)

--     it("in header: start", function()
--         local args = {mark_label = "a", lines = tostring(Header({content = "[a]()"})), index_type="end"}
--         assert.are.same(3, Parser():get_mark_content_line_index(args))
--     end)
-- end)

-- describe("separate_mark_content", function()
--     it("mark is missing", function()
--         local header = tostring(Header({content = "[a]()"}))
--         local header_content = {"- b", "- c"}
--         local after = List.from({""}, tostring(Header()))
--         local lines = List.from(header, header_content, after)
--         assert.are.same({lines, {}, {}}, Parser():separate_mark_content("x", lines))
--     end)

--     it("at start", function()
--         local header = tostring(Header({content = "[a]()"}))
--         local header_content = {"- b", "- c"}
--         local after = List.from({""}, tostring(Header()))
--         local lines = List.from(header, header_content, after)
--         local expected = {
--             {},
--             List.from(header, header_content),
--             after
--         }
--         assert.are.same(expected, Parser():separate_mark_content("a", lines))
--     end)

--     it("at end", function()
--         local before = List.from(tostring(Header({content = "[a]()"})), {"- x", "- y", "", ""})
--         local content = List.from(
--             tostring(Header({content = "[b]()", size = "large"})),
--             {"123", "- y", ""},
--             tostring(Header({content = "subheader)"})),
--             {"hunter", "test", ""}
--         )
--         local lines = List.from(before, content, {})
--         local expected = {before, content, {}}
--         assert.are.same(expected, Parser():separate_mark_content("b", lines))
--     end)

--     it("in middle", function()
--         local before = List.from(
--             tostring(Header({content = "[a]()", size = "large"})),
--             {"- x", "- y", ""},
--             {""}
--         )
--         local content = List.from(
--             tostring(Header({content = "[b]()", size = "medium"})),
--             {"123", "- y", ""},
--             tostring(Header({content = "subheader)"})),
--             {"hunter", "test"}
--         )

--         local after = List.from(
--             {""},
--             tostring(Header({content = "[c]()", size = "medium"})),
--             {"more", "stuff"}
--         )

--         local lines = List.from(before, content, after)
--         local expected = {before, content, after}
--         assert.are.same({before, content, after}, Parser():separate_mark_content("b", lines))
--     end)
-- end)

-- describe("remove_empty_lines", function()
--     it("!tail", function()
--         assert.are.same({"a", ""}, Parser.remove_empty_lines({"", "a", ""}, {tail = false}))
--     end)
--     it("!head", function()
--         assert.are.same({"", "a"}, Parser.remove_empty_lines({"", "a", ""}, {head = false}))
--     end)
--     it("both", function()
--         assert.are.same({"a"}, Parser.remove_empty_lines({"", "a", ""}))
--     end)
-- end)

-- describe("merge_line_sets", function()
--     it("works", function()
--         local sets = {
--             {"", "a", ""},
--             {"", "b"},
--             {"c", ""},
--         }
--         local expected = {"", "a", "", "b", "", "c", ""}
--         assert.are.same(expected, Parser.merge_line_sets(sets))
--     end)
-- end)

-- describe("remove_mark_content", function()
--     before_each(function()
--         test_file_path:unlink()
--     end)

--     after_each(function()
--         test_file_path:unlink()
--     end)

--     it("works", function()
--         local before = List.from(
--             tostring(Header({content = "[a]()", size = "large"})),
--             {"- x", "- y", ""},
--             {""}
--         )
--         local content = List.from(
--             tostring(Header({content = "[b]()", size = "medium"})),
--             {"123", "- y", ""},
--             tostring(Header({content = "subheader)"})),
--             {"hunter", "test"}
--         )

--         local padding = {""}

--         local after = List.from(
--             tostring(Header({content = "[c]()", size = "medium"})),
--             {"more", "stuff"}
--         )


--         test_file_path:write(List.from(before, content, padding, after))

--         local location = Location({path = tostring(test_file_path), label = 'b'})

--         assert.are.same(content, Parser():remove_mark_content(location))
--         assert.are.same(Parser.merge_line_sets({before, after}), test_file_path:readlines())
--     end)
-- end)

-- describe("add_mark_content", function()
--     local from_mark_location = Location({path = tostring(test_file_path), label = 'a'})
--     local to_mark_location = Location({path = tostring(other_test_file_path), label = 'b'})
--     local lines = {"- x", "- y", ""}
--     local new_content = List.from(tostring(Header({content = "[a]()", size = "large"})), lines)

--     before_each(function()
--         test_file_path:unlink()
--         other_test_file_path:unlink()
--     end)

--     after_each(function()
--         test_file_path:unlink()
--         other_test_file_path:unlink()
--     end)

--     it("no file, !include_mark", function()
--         Parser():add_mark_content({
--             new_content = new_content,
--             from_mark_location = from_mark_location,
--             to_mark_location = to_mark_location,
--         })
--         assert.are.same(List.from({""}, lines), Path(to_mark_location.path):readlines())
--     end)

--     it("no file, include_mark", function()
--         local expected = List.from(
--             tostring(Header({content = "[b]()", size = "large"})),
--             lines
--         )

--         Parser():add_mark_content({
--             new_content = new_content,
--             from_mark_location = from_mark_location,
--             to_mark_location = to_mark_location,
--             include_mark = true
--         })
--         assert.are.same(expected, Path(to_mark_location.path):readlines())
--     end)

--     it("no existing mark content, include_mark", function()
--         local existing_file_content = {"a", "b", ""}
--         Path(to_mark_location.path):write(existing_file_content)

--         local expected = List.from(
--             existing_file_content,
--             tostring(Header({content = "[b]()", size = "large"})),
--             lines
--         )

--         Parser():add_mark_content({
--             new_content = new_content,
--             from_mark_location = from_mark_location,
--             to_mark_location = to_mark_location,
--             include_mark = true
--         })
--         assert.are.same(expected, Path(to_mark_location.path):readlines())
--     end)

--     it("existing mark content, !include_mark", function()
--         local existing_file_content = List.from(
--             {"a", "b", ""},
--             tostring(Header({content = "[b]()", size = "large"})),
--             {"1", "2", ""},
--             tostring(Header({content = "[c]()", size = "large"})),
--             {"z", "w", ""}
--         )

--         local expected = List.from(
--             {"a", "b", ""},
--             tostring(Header({content = "[b]()", size = "large"})),
--             {"1", "2", ""},
--             lines,
--             tostring(Header({content = "[c]()", size = "large"})),
--             {"z", "w", ""}
--         )

--         Path(to_mark_location.path):write(existing_file_content)

--         Parser():add_mark_content({
--             new_content = new_content,
--             from_mark_location = from_mark_location,
--             to_mark_location = to_mark_location,
--             include_mark = false,
--         })
--         assert.are.same(expected, Path(to_mark_location.path):readlines())
--     end)
-- end)
