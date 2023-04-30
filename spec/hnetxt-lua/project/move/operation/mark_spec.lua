table = require("hneutil.table")
local Path = require("hneutil.path")
local Header = require("hnetxt-lua.text.header")
local Parser = require("hnetxt-lua.parse")

local test_dir = Path.joinpath(Path.tempdir(), "test-dir")
local test_file_one = Path.joinpath(test_dir, "test-file-1.md")
local test_file_two = Path.joinpath(test_dir, "test-file-2.md")

before_each(function()
    Path.rmdir(test_dir, true)
end)

after_each(function()
    Path.rmdir(test_dir, true)
end)

local MarkOperation = require("hnetxt-lua.project.move.operation.mark")

describe("to_dir_file.transform_target", function()
    it("works", function()
        assert.are.same("c/b.md", MarkOperation.to_dir_file.transform_target("c", "a.md:b"))
    end)
end)

describe("process", function()
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
        MarkOperation.process({[source_mark] = test_file_two})

        assert.are.same(
            Parser.merge_line_sets({pre_mark_source_content, post_mark_source_content}),
            Path.readlines(test_file_one)
        )
    end)

    it("creates file", function()
        MarkOperation.process({[source_mark] = test_file_two})

        assert.are.same(
            mark_text,
            Path.readlines(test_file_two)
        )
    end)

    it("appends to file", function()
        local target_contents = {"1", "2", "3", ""}
        Path.write(test_file_two, target_contents)

        MarkOperation.process({[source_mark] = test_file_two})

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

        MarkOperation.process({[source_mark] = test_file_two .. ":target"})

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
