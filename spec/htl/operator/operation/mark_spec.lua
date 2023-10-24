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
        Header({content = "[q]()"}):get_lines(),
        {"r", "s", ""}
    )

    local mark_text = {"b", "c"}
    local mark_content = List.from(
        Header({content = "[a]()"}):get_lines(),
        mark_text,
        {""}
    )

    local post_mark_source_content = List.from(
        Header({content = "[x]()"}):get_lines(),
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
            mark_text,
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
            Header({content = "[pre]()"}):get_lines(),
            {"before", ""}
        )

        local target_mark_content = List.from(
            Header({content = "[target]()"}):get_lines(),
            {"already", "existing", "content"},
            {""}
        )

        local target_post_mark_content = List.from(
            Header({content = "[post]()"}):get_lines(),
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

describe("end to end", function()
    it("move", function()
        local a_path = test_dir:join("a.md")
        local b_path = test_dir:join("b.md")
        local c_path = test_dir:join("c.md")

        local mark_content = {"mark content"}

        local a_content_old = List.from(
            {"pre"},
            Header({content = "[x]()"}):get_lines(),
            mark_content,
            Header({content = "[y]()"}):get_lines(),
            {"post"}
        )

        local a_content_new = List.from(
            {"pre", ""},
            Header({content = "[y]()"}):get_lines(),
            {"post"}
        )

        local b_content_old = List.from(
            {"abcd"},
            Header({content = "[b mark]()"}):get_lines(),
            {"after"}
        )

        local b_content_new = List.from(
            {"abcd"},
            Header({content = "[b mark]()"}):get_lines(),
            {"after", ""},
            Header({content = "[y]()", size="large"}):get_lines(),
            {""},
            mark_content
        )

        local c_content_old = {"[ref to a:x](a.md:x)"}
        local c_content_new = {"[ref to a:x](b.md:y)"}

        Path.write(a_path, a_content_old)
        Path.write(b_path, b_content_old)
        Path.write(c_path, c_content_old)

        Operator.move(tostring(a_path) .. ":x", tostring(b_path) .. ":y")

        assert.are.same(a_content_new, a_path:readlines())
        assert.are.same(b_content_new, b_path:readlines())
        assert.are.same(c_content_new, c_path:readlines())
    end)
end)
