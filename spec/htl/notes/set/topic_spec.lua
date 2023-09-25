local Path = require("hl.Path")
local Fields = require("htl.notes.field")

local TopicSet = require("htl.notes.set.topic")

local project_root = Path.join(tostring(Path.tempdir), "test-project-root")

local topic_set_dir = Path.join(project_root, "files")

local topic_1_dir = Path.join(topic_set_dir, "a")
local topic_1_statement = Path.join(topic_1_dir, "@.md")
local topic_1_file_1 = Path.join(topic_1_dir, "1.md")
local topic_1_file_2 = Path.join(topic_1_dir, "2.md")
local topic_1_file_3 = Path.join(topic_1_dir, "3.md")
local topic_1_file_a = Path.join(topic_1_dir, "a.md")

local topic_2_dir = Path.join(topic_set_dir, "b")
local topic_2_statement = Path.join(topic_2_dir, "@.md")
local topic_2_file_1 = Path.join(topic_2_dir, "1.md")
local topic_2_file_2 = Path.join(topic_2_dir, "2.md")

local files = {
    topic_1_statement,
    topic_1_file_1,
    topic_1_file_2,
    topic_1_file_3,
    topic_1_file_a,
    topic_2_statement,
    topic_2_file_1,
    topic_2_file_2,
}

before_each(function()
    Path.rmdir(project_root, true)
    for _, p in ipairs(files) do
        Path.touch(p)
    end

    stub(Fields, "format", function(...) return ... end)
end)

after_each(function()
    Path.rmdir(project_root, true)
    Fields.format:revert()
end)

describe("format_topics", function()
    it("works", function()
        assert.are.same(
            {
                a = {statement = {x = 2}, file = {y = 3}},
                b = {statement = {x = 3}, file = {y = 3}},
            },
            TopicSet.format_topics({
                topics = {"a", b = {statement = {x = 3}}},
                statement = {x = 2},
                file = {y = 3}
            })
        )
    end)
end)

describe("format", function()
    it("works", function()
        assert.are.same(
            {
                topics = {},
                statement = {fields = {}, filters = {}},
                file = {fields = {}, filters = {}},
            },
            TopicSet.format()
        )
    end)

    it("sets defaults", function()
        local actual = TopicSet.format({topics = {"a", b = {file = {fields = {x = true}}}}})
        assert.are.same(
            {
                topics = {
                    a = {
                        statement = {fields = {}, filters = {}},
                        file = {fields = {}, filters = {}},
                    },
                    b = {
                        statement = {fields = {}, filters = {}},
                        file = {fields = {x = true}, filters = {}},
                    }
                },
                statement = {fields = {}, filters = {}},
                file = {fields = {}, filters = {}},
            },
            actual
        )
    end)
end)

describe("is_topic", function()
    local topic_set = TopicSet(topic_set_dir)

    it("self.path/dir: +", function()
        assert(topic_set:is_topic(topic_1_dir))
    end)

    it("self.path/dir/@.md: +", function()
        assert(topic_set:is_topic(topic_1_statement))
    end)

    it("self.path: -", function()
        assert.falsy(topic_set:is_topic(topic_set_dir))
    end)

    it("nil: -", function()
        assert.falsy(topic_set:is_topic())
    end)
end)

describe("is_topic_dir", function()
    local topic_set = TopicSet(topic_set_dir)

    it("self.path/dir: +", function()
        assert(topic_set:is_topic_dir(topic_1_dir))
    end)
end)

describe("is_topic_dir", function()
    local topic_set = TopicSet(topic_set_dir)

    it("self.path/dir/@.md: +", function()
        assert(topic_set:is_topic_statement(topic_1_statement))
    end)
end)

describe("as_topic_statement", function()
    local topic_set = TopicSet(topic_set_dir)

    it("dir/topic/@.md", function()
        assert.are.same(topic_1_statement, topic_set:as_topic_statement(topic_1_statement))
    end)

    it("dir/topic/x.md", function()
        assert.are.same(topic_1_statement, topic_set:as_topic_statement(topic_1_statement))
    end)

    it("dir/topic", function()
        assert.are.same(topic_1_statement, topic_set:as_topic_statement(topic_1_dir))
    end)

    it("dir/file.md", function()
        assert.are.same(topic_1_statement, topic_set:as_topic_statement(Path.with_suffix(topic_1_dir, ".md")))
    end)

    it("dir/a/b.md: -", function()
        assert.falsy(topic_set:as_topic_statement(Path.join(topic_set_dir, "a", "b", "c.md")))
    end)
end)

describe("is_topic_file", function()
    local topic_set = TopicSet(topic_set_dir)

    it("-: topic_statement", function()
        assert.falsy(topic_set:is_topic_file(topic_1_statement))
    end)

    it("+: topic_file", function()
        assert(topic_set:is_topic_file(topic_1_file_1))
    end)
end)

describe("is_topic_content", function()
    local topic_set = TopicSet(topic_set_dir)

    it("+: topic_statement", function()
        assert(topic_set:is_topic_content(topic_1_statement))
    end)

    it("+: topic_file", function()
        assert(topic_set:is_topic_content(topic_1_file_1))
    end)

    it("+: topic_dir", function()
        assert(topic_set:is_topic_content(topic_1_dir))
    end)
end)

describe("path_topic", function()
    local topic_set = TopicSet(topic_set_dir)

    it("+: topic_statement", function()
        assert.are.same('a', topic_set:path_topic(topic_1_statement))
    end)

    it("+: topic_file", function()
        assert.are.same('a', topic_set:path_topic(topic_1_file_1))
    end)

    it("+: topic_dir", function()
        assert.are.same('a', topic_set:path_topic(topic_1_dir))
    end)
end)

describe("get_topic_statements", function()
    local topic_set = TopicSet(topic_set_dir)

    it("works", function()
        local actual = topic_set:get_topic_statements()
        table.sort(actual)
        assert.are.same({topic_1_statement, topic_2_statement}, actual)
    end)
end)

describe("get_topic_files", function()
    local topic_set = TopicSet(topic_set_dir)

    it("works", function()
        local actual = topic_set:get_topic_files(topic_1_dir)
        table.sort(actual)
        assert.are.same(
            {
                topic_1_file_1,
                topic_1_file_2,
                topic_1_file_3,
                topic_1_file_a,
            },
            actual
        )
    end)
end)

describe("get_path_to_touch", function()
    local topic_set = TopicSet(topic_set_dir)

    it("dir/topic/@.md → dir/topic/@.md", function()
        assert.are.same(topic_1_statement, topic_set:get_path_to_touch(topic_1_statement))
    end)

    it("dir/topic → dir/topic/@.md", function()
        assert.are.same(topic_1_statement, topic_set:get_path_to_touch(topic_1_dir))
    end)

    it("dir/topic.md → dir/topic/@.md", function()
        assert.are.same(topic_1_statement, topic_set:get_path_to_touch(Path.with_suffix(topic_1_dir, ".md")))
    end)

    it("dir/topic/X.md → dir/topic/X.md", function()
        assert.are.same(topic_1_file_1, topic_set:get_path_to_touch(topic_1_file_1))
    end)

    it("dir/topic + {date = true} → dir/topic/DATE.md", function()
        assert.are.same(
            Path.join(topic_1_dir, os.date("%Y%m%d") .. ".md"),
            topic_set:get_path_to_touch(topic_1_dir, {date = true})
        )
    end)

    it("dir/topic + {next_note = true} - → dir/topic/1234.md", function()
        assert.are.same(
            Path.join(topic_1_dir, "4.md"),
            topic_set:get_path_to_touch(topic_1_dir, {next = true})
        )
    end)
end)

describe("path_config", function()
    local topic_config = {
        statement = {fields = {x = {default = 'statement'}}, filters = {y = 1}},
        file = {fields = {x = {default = 'file'}}, filters = {y = 2}},
    }

    local default_config = {
        statement = {fields = {x = {default = 'set statement'}}, filters = {y = 3}},
        file = {fields = {x = {default = 'set file'}}, filters = {y = 4}},
    }

    local topic_set = TopicSet(
        topic_set_dir,
        {
            topics = {a = topic_config},
            statement = default_config.statement,
            file = default_config.file,
        }
    )

    it("default statement", function()
        assert.are.same(default_config.statement, topic_set:path_config(topic_2_statement))
    end)

    it("default file", function()
        assert.are.same(default_config.file, topic_set:path_config(topic_2_file_1))
    end)

    it("topic statement", function()
        assert.are.same(topic_config.statement, topic_set:path_config(topic_1_statement))
    end)

    it("topic file", function()
        assert.are.same(topic_config.file, topic_set:path_config(topic_1_file_1))
    end)
end)

describe("touch", function()
    before_each(function()
        Fields.format:revert()
    end)

    after_each(function()
        stub(Fields, 'format')
    end)

    local topic_set = TopicSet(topic_set_dir, {
        topics = {},
        statement = {filters = {}, fields = Fields.format({a = false})},
        file = {filters = {}, fields = Fields.format({b = true})}
    })

    it("statement", function()
        local path = topic_1_statement
        Path.unlink(path)

        assert.are.same(path, topic_set:touch(path))
        assert(Path.exists(path))

        assert.are.same(
            {a = false, date = tonumber(os.date("%Y%m%d"))},
            topic_set:path_file(path):get_metadata()
        )
    end)

    it("file", function()
        local path = topic_1_file_1
        Path.unlink(path)

        assert.are.same(path, topic_set:touch(path))
        assert(Path.exists(path))

        assert.are.same(
            {b = true, date = tonumber(os.date("%Y%m%d"))},
            topic_set:path_file(path):get_metadata()
        )
    end)
end)
