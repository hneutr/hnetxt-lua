table = require("hl.table")
local Path = require("hl.path")

local Fields = require("htl.project.notes.fields")
local ResponseEntry = require("htl.project.notes.entry.response")

local prompt_key = "prompts"
local key = Path.joinpath(prompt_key, "responses")

local test_project_root = Path.joinpath(Path.tempdir(), "test-project-root")
local test_file = Path.joinpath(test_project_root, "other.md")

local test_prompt_dir = Path.joinpath(test_project_root, prompt_key)
local test_prompt_1 = Path.joinpath(test_prompt_dir, "p1.md")
local test_prompt_2 = Path.joinpath(test_prompt_dir, "p2.md")

local test_response_dir = Path.joinpath(test_project_root, key)

local test_response_1_dir = Path.joinpath(test_response_dir, "p1")
local test_response_1_1 = Path.joinpath(test_response_1_dir, "20230101.md")
local test_response_1_2 = Path.joinpath(test_response_1_dir, os.date("%Y%m%d") .. ".md")

local test_response_2_dir = Path.joinpath(test_response_dir, "p2")
local test_response_2_1 = Path.joinpath(test_response_2_dir, "20230201.md")
local test_response_2_2 = Path.joinpath(test_response_2_dir, os.date("%Y%m%d") .. ".md")

local test_entries = {
    test_file,
    test_prompt_1,
    test_prompt_2,
    test_response_1_1,
    test_response_1_2,
    test_response_2_1,
    test_response_2_2,
}

before_each(function()
    Path.rmdir(test_project_root, true)
    for _, p in ipairs(test_entries) do
        Path.touch(p)
    end
end)

after_each(function()
    Path.rmdir(test_project_root, true)
end)

describe("get_entry", function()
    it("works", function()
        assert.are.same(
            {type = 'response', fields = {pinned = false}, prompt_key = 'prompt'},
            ResponseEntry.get_entry('prompt')
        )
    end)
end)

describe("find_items", function()
    it("works", function()
        local expected = {test_response_1_1, test_response_1_2, test_response_2_1, test_response_2_2}
        local actual = ResponseEntry(key, {}, {}, test_project_root):items()
        table.sort(expected)
        table.sort(actual)

        assert.are.same(expected, actual)
    end)
end)

describe("response_entry_set", function()
    it("works", function()
        assert.are.same(
            "b",
            ResponseEntry(key, {prompt_key = "a"}, {a = "b"}, test_project_root).prompt_entry_set
        )
    end)
end)

describe("path", function()
    it("works", function()
        assert.are.same(
            Path.joinpath(test_project_root, key, "abc",  os.date("%Y%m%d") .. ".md"),
            ResponseEntry(key, {}, {}, test_project_root):path("abc.md")
        )
    end)
end)
