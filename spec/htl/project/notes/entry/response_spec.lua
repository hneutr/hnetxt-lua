table = require("hl.table")
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local Fields = require("htl.project.notes.fields")
local ResponseEntry = require("htl.project.notes.entry.response")
local PromptEntry = require("htl.project.notes.entry.prompt")

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

local prompt
local response
local entry_sets

local function setup_entry_sets()
    response_config = ResponseEntry.get_entry(prompt_key)
    response_config.fields = Fields.format(response_config.fields)

    response = ResponseEntry(key, response_config, {}, test_project_root)
    prompt = PromptEntry(prompt_key, {response_key = key}, {}, test_project_root)

    entry_sets = {[key] = response, [prompt_key] = prompt}
    prompt.entry_sets = entry_sets
    response.entry_sets = entry_sets
end


before_each(function()
    Path.rmdir(test_project_root, true)
    for _, p in ipairs(test_entries) do
        Path.touch(p)
    end

    prompt = nil
    response = nil
    entry_sets = {}
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

describe("paths", function()
    it("works", function()
        local expected = {test_response_1_1, test_response_1_2, test_response_2_1, test_response_2_2}
        local actual = ResponseEntry(key, {}, {}, test_project_root):paths()
        table.sort(expected)
        table.sort(actual)

        assert.are.same(expected, actual)
    end)
end)

describe("response_entry_set", function()
    it("works", function()
        assert.are.same(
            "b",
            ResponseEntry(key, {prompt_key = "a"}, {a = "b"}, test_project_root):prompt_entry_set()
        )
    end)
end)

describe("response_dir_for_path", function()
    local prompt = PromptEntry(prompt_key, {}, {}, test_project_root)
    local response = ResponseEntry(key, {prompt_key = prompt_key}, {[prompt_key] = prompt}, test_project_root)

    it("not from prompts", function()
        assert.is_nil(response:response_dir_for_path("abc.md"))
    end)

    it("from prompt", function()
        assert.are.same(test_response_1_dir, response:response_dir_for_path(test_prompt_1))
    end)

    it("from response", function()
        assert.are.same(test_response_1_dir, response:response_dir_for_path(test_response_1_1))
    end)
end)

describe("prompt_for_path", function()
    before_each(function()
        setup_entry_sets()
    end)

    it("isn't relative", function()
        assert.is_nil(response:prompt_for_path(test_file))
    end)

    it("is a prompt", function()
        assert.are.same(test_prompt_1, response:prompt_for_path(test_prompt_1))
    end)

    it("is a response", function()
        assert.are.same(test_prompt_1, response:prompt_for_path(test_response_1_1))
    end)

    it("is a response dir", function()
        assert.are.same(test_prompt_1, response:prompt_for_path(test_response_1_dir))
    end)
end)

describe("move", function()
    it("moves dated entry", function()
        setup_entry_sets()

        local old_response = test_response_1_1
        local old_date = Path.stem(old_response)
        local new_date = 19932001
        local new_response = Path.with_stem(old_response, new_date)

        response:new_entry(old_response, {date = old_date})

        assert(Path.exists(old_response))
        assert.are.same(old_date, response:get_metadata(old_response).date)
        assert.falsy(Path.exists(new_response))

        response:move(old_response, new_response)

        assert.falsy(Path.exists(old_response))
        assert.are.same(new_date, response:get_metadata(new_response).date)
        assert(Path.exists(new_response))
    end)

    it("doesn't move non-date entry", function()
        setup_entry_sets()

        local old_response = Path.joinpath(test_response_1_dir, 'old-response.md')
        local new_response = Path.with_stem(old_response, 'new-response')

        local date = os.date("%Y%m%d")

        response:new_entry(old_response)

        assert(Path.exists(old_response))
        assert.are.same(date, response:get_metadata(old_response).date)
        assert.falsy(Path.exists(new_response))

        response:move(old_response, new_response)

        assert.falsy(Path.exists(old_response))
        assert.are.same(date, response:get_metadata(new_response).date)
        assert(Path.exists(new_response))
    end)
end)

describe("set_metadata", function()
    it("moves date-named entry", function()
        setup_entry_sets()

        local old_response = test_response_1_1
        local old_date = Path.stem(old_response)
        local new_date = "19932001"
        local new_response = Path.with_stem(old_response, new_date)

        response:new_entry(old_response, {date = old_date})

        assert(Path.exists(old_response))
        assert.are.same(old_date, response:get_metadata(old_response).date)
        assert.falsy(Path.exists(new_response))

        response:set_metadata(old_response, {date = new_date})

        assert.falsy(Path.exists(old_response))
        assert.are.same(new_date, response:get_metadata(new_response).date)
        assert(Path.exists(new_response))
    end)

    it("doesn't move a named file", function()
        setup_entry_sets()

        local response_path = Path.joinpath(test_response_1_dir, 'response.md')

        local old_date = os.date("%Y%m%d")
        local new_date = "19932001"

        response:new_entry(response_path, {date = old_date})

        assert(Path.exists(response_path))
        assert.are.same(old_date, response:get_metadata(response_path).date)

        response:set_metadata(response_path, {date = new_date})

        assert(Path.exists(response_path))
        assert.are.same(new_date, response:get_metadata(response_path).date)
    end)
end)
