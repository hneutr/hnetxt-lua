local List = require("hl.List")

local Path = require("hl.Path")
local Header = require("htl.text.header")
local Parser = require("htl.parse")
local Project = require("htl.project")
local Mirror = require("htl.project.mirror")

local Operator = require("htl.operator")
local MarkOperation = require("htl.operator.operation.mark")

local test_dir = Path.tempdir:join("test-dir")
local test_file_one = test_dir:join("test-file-1.md")
local test_file_two = test_dir:join("test-file-2.md")

before_each(function()
    test_dir:rmdir(true)
    stub(Project, 'root_from_path')
    Project.root_from_path.returns(test_dir)
end)

after_each(function()
    test_dir:rmdir(true)
    Project.root_from_path:revert()
end)

describe("to_dir_file.transform_target", function()
    it("works", function()
        assert.are.same("c/b.md", MarkOperation.to_dir_file.transform_target("c", "a.md:b"))
    end)
end)

describe("move", function()
    local pre_mark_source_content = List.from(
        tostring(Header({content = "[q]()"})),
        {"r", "s", ""}
    )

    local mark_text = {"b", "c"}
    local mark_content = List.from(
        tostring(Header({content = "[a]()"})),
        mark_text,
        {""}
    )

    local post_mark_source_content = List.from(
        tostring(Header({content = "[x]()"})),
        {"y", "z"}
    )

    local source_content = List.from(pre_mark_source_content, mark_content, post_mark_source_content)
    local source_mark = tostring(test_file_one) .. ":a"

    before_each(function()
        test_file_one:write(source_content)
    end)

    it("removes content", function()
        MarkOperation.move({[source_mark] = tostring(test_file_two)})

        assert.are.same(
            Parser.merge_line_sets({pre_mark_source_content, post_mark_source_content}),
            test_file_one:readlines()
        )
    end)

    it("creates file", function()
        MarkOperation.move({[source_mark] = tostring(test_file_two)})

        assert.are.same(
            List.from({""}, mark_text),
            test_file_two:readlines()
        )
    end)

    it("appends to file", function()
        local target_contents = {"1", "2", "3", ""}
        Path.write(test_file_two, target_contents)

        MarkOperation.move({[source_mark] = tostring(test_file_two)})

        assert.are.same(
            Parser.merge_line_sets({target_contents, mark_text}),
            test_file_two:readlines()
        )
    end)

    it("appends to mark", function()
        local target_pre_mark_content = List.from(
            tostring(Header({content = "[pre]()"})),
            {"before", ""}
        )

        local target_mark_content = List.from(
            tostring(Header({content = "[target]()"})),
            {"already", "existing", "content"},
            {""}
        )

        local target_post_mark_content = List.from(
            tostring(Header({content = "[post]()"})),
            {"after"}
        )

        local target_content = List.from(
            {},
            target_pre_mark_content,
            target_mark_content,
            target_post_mark_content
        )

        test_file_two:write(target_content)

        MarkOperation.move({[source_mark] = tostring(test_file_two) .. ":target"})

        assert.are.same(
            Parser.merge_line_sets({
                target_pre_mark_content,
                target_mark_content,
                mark_text,
                target_post_mark_content
            }),
            test_file_two:readlines()
        )
    end)
end)

-- describe("end to end", function()
--     it("move", function()
--         local a_path = Path.joinpath(test_dir, "a.md")
--         local b_path = Path.joinpath(test_dir, "b.md")

--         local c_path = Path.joinpath(test_dir, "c.md")

--         local mark_content = {"mark content"}

--         local a_content_old = List.from(
--             {"pre"},
--             tostring(Header({content = "[x]()"})),
--             mark_content,
--             tostring(Header({content = "[y]()"})),
--             {"post"}
--         )

--         local a_content_new = List.from(
--             {"pre", ""},
--             tostring(Header({content = "[y]()"})),
--             {"post"}
--         )

--         local b_content_old = List.from(
--             {"abcd"},
--             tostring(Header({content = "[b mark]()"})),
--             {"after"}
--         )

--         local b_content_new = List.from(
--             {"abcd"},
--             tostring(Header({content = "[b mark]()"})),
--             {"after", ""},
--             tostring(Header({content = "[y]()", size="large"})),
--             mark_content
--         )

--         local c_content_old = {"[ref to a:x](a.md:x)"}
--         local c_content_new = {"[ref to a:x](b.md:y)"}

--         Path.write(a_path, a_content_old)
--         Path.write(b_path, b_content_old)
--         Path.write(c_path, c_content_old)

--         Operator.move(a_path .. ":x", b_path .. ":y")

--         assert.are.same(a_content_new, Path.readlines(a_path))
--         assert.are.same(b_content_new, Path.readlines(b_path))
--         assert.are.same(c_content_new, Path.readlines(c_path))
--     end)
-- end)
