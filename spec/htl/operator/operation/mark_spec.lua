table = require("hl.table")

local Path = require("hl.path")
local Header = require("htl.text.header")
local Parser = require("htl.parse")
local Project = require("htl.project")
local Mirror = require("htl.project.mirror")

local Operator = require("htl.operator")
local MarkOperation = require("htl.operator.operation.mark")

local test_dir = Path.joinpath(Path.tempdir(), "test-dir")
local test_file_one = Path.joinpath(test_dir, "test-file-1.md")
local test_file_two = Path.joinpath(test_dir, "test-file-2.md")

before_each(function()
    Path.rmdir(test_dir, true)
    stub(Project, 'root_from_path')
    Project.root_from_path.returns(test_dir)
end)

after_each(function()
    Path.rmdir(test_dir, true)
    Project.root_from_path:revert()
end)

describe("to_dir_file.transform_target", function()
    it("works", function()
        assert.are.same("c/b.md", MarkOperation.to_dir_file.transform_target("c", "a.md:b"))
    end)
end)

describe("move", function()
    local pre_mark_source_content = table.list_extend(
        tostring(Header({content = "[q]()"})),
        {"r", "s", ""}
    )

    local mark_text = {"b", "c"}
    local mark_content = table.list_extend(
        tostring(Header({content = "[a]()"})),
        mark_text,
        {""}
    )

    local post_mark_source_content = table.list_extend(
        tostring(Header({content = "[x]()"})),
        {"y", "z"}
    )

    local source_content = table.list_extend({}, pre_mark_source_content, mark_content, post_mark_source_content)
    local source_mark = test_file_one .. ":a"

    before_each(function()
        Path.write(test_file_one, source_content)
    end)

    it("removes content", function()
        MarkOperation.move({[source_mark] = test_file_two})

        assert.are.same(
            Parser.merge_line_sets({pre_mark_source_content, post_mark_source_content}),
            Path.readlines(test_file_one)
        )
    end)

    it("creates file", function()
        MarkOperation.move({[source_mark] = test_file_two})

        assert.are.same(
            mark_text,
            Path.readlines(test_file_two)
        )
    end)

    it("appends to file", function()
        local target_contents = {"1", "2", "3", ""}
        Path.write(test_file_two, target_contents)

        MarkOperation.move({[source_mark] = test_file_two})

        assert.are.same(
            Parser.merge_line_sets({target_contents, mark_text}),
            Path.readlines(test_file_two)
        )
    end)

    it("appends to mark", function()
        local target_pre_mark_content = table.list_extend(
            tostring(Header({content = "[pre]()"})),
            {"before", ""}
        )

        local target_mark_content = table.list_extend(
            tostring(Header({content = "[target]()"})),
            {"already", "existing", "content"},
            {""}
        )

        local target_post_mark_content = table.list_extend(
            tostring(Header({content = "[post]()"})),
            {"after"}
        )

        local target_content = table.list_extend(
            {},
            target_pre_mark_content,
            target_mark_content,
            target_post_mark_content
        )

        Path.write(test_file_two, target_content)

        MarkOperation.move({[source_mark] = test_file_two .. ":target"})

        assert.are.same(
            Parser.merge_line_sets({
                target_pre_mark_content,
                target_mark_content,
                mark_text,
                target_post_mark_content
            }),
            Path.readlines(test_file_two)
        )
    end)
end)

describe("end to end", function()
    it("move", function()
        local a_path = Path.joinpath(test_dir, "a.md")
        local b_path = Path.joinpath(test_dir, "b.md")

        local c_path = Path.joinpath(test_dir, "c.md")

        local mark_content = {"mark content"}

        local a_content_old = table.list_extend(
            {"pre"},
            tostring(Header({content = "[x]()"})),
            mark_content,
            tostring(Header({content = "[y]()"})),
            {"post"}
        )

        local a_content_new = table.list_extend(
            {"pre", ""},
            tostring(Header({content = "[y]()"})),
            {"post"}
        )

        local b_content_old = table.list_extend(
            {"abcd"},
            tostring(Header({content = "[b mark]()"})),
            {"after"}
        )

        local b_content_new = table.list_extend(
            {"abcd"},
            tostring(Header({content = "[b mark]()"})),
            {"after", ""},
            tostring(Header({content = "[y]()", size="large"})),
            mark_content
        )

        local c_content_old = {"[ref to a:x](a.md:x)"}
        local c_content_new = {"[ref to a:x](b.md:y)"}

        Path.write(a_path, a_content_old)
        Path.write(b_path, b_content_old)
        Path.write(c_path, c_content_old)

        Operator.move(a_path .. ":x", b_path .. ":y")

        assert.are.same(a_content_new, Path.readlines(a_path))
        assert.are.same(b_content_new, Path.readlines(b_path))
        assert.are.same(c_content_new, Path.readlines(c_path))
    end)
end)
