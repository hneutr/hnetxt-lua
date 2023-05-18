-- local Path = require("hl.path")
-- local Field = require("htl.notes.field")
-- local PromptSet = require("htl.notes.set.prompt")
-- local ResponseEntry = require("htl.notes.entry.response")

-- local key = "prompts"
-- local response_key = Path.joinpath(key, "responses")

-- local test_project_root = Path.joinpath(Path.tempdir(), "test-project-root")

-- local test_prompt_dir = Path.joinpath(test_project_root, key)
-- local test_prompt_1 = Path.joinpath(test_prompt_dir, 'p1.md')
-- local test_prompt_2 = Path.joinpath(test_prompt_dir, 'p2.md')

-- local test_response_dir = Path.joinpath(test_project_root, response_key)

-- local test_response_1_dir = Path.joinpath(test_response_dir, "p1")
-- local test_response_1_1 = Path.joinpath(test_response_1_dir, "20230101.md")
-- local test_response_1_2 = Path.joinpath(test_response_1_dir, os.date("%Y%m%d") .. ".md")

-- local test_response_2_dir = Path.joinpath(test_response_dir, "p2")
-- local test_response_2_1 = Path.joinpath(test_response_2_dir, "20230201.md")
-- local test_response_2_2 = Path.joinpath(test_response_2_dir, os.date("%Y%m%d") .. ".md")

-- local test_entries = {
--     test_prompt_1,
--     test_prompt_2,
--     test_response_1_1,
--     test_response_1_2,
--     test_response_2_1,
--     test_response_2_2,
-- }

-- local prompt
-- local response
-- local entry_sets

-- local function setup_entry_sets()
--     response_config = ResponseEntry.get_entry(key)
--     response_config.fields = Field.format(response_config.field)

--     response = ResponseEntry(response_key, response_config, {}, test_project_root)
--     prompt = PromptSet(key, {response_key = response_key}, {}, test_project_root)

--     entry_sets = {[response_key] = response, [key] = prompt}
--     prompt.entry_sets = entry_sets
--     response.entry_sets = entry_sets
-- end


-- before_each(function()
--     Path.rmdir(test_project_root, true)
--     for _, p in ipairs(test_entries) do
--         Path.touch(p)
--     end

--     prompt = nil
--     response = nil
--     entry_sets = {}
-- end)

-- after_each(function()
--     Path.rmdir(test_project_root, true)
-- end)

-- describe("get_response_key", function()
--     it("nothing", function()
--         assert.are.same('a/responses', PromptSet.get_response_key('a'))
--     end)

--     it("key", function()
--         assert.are.same('a/answers', PromptSet.get_response_key('a', "answers"))
--     end)

--     it("..", function()
--         assert.are.same('a/responses', PromptSet.get_response_key('a/b', ".."))
--     end)

--     it("../key", function()
--         assert.are.same('a/answers', PromptSet.get_response_key('a/b', "../answers"))
--     end)

--     it("../..", function()
--         assert.are.same('a/responses', PromptSet.get_response_key('a/b/c', "../.."))
--     end)

--     it("../../key", function()
--         assert.are.same('a/answers', PromptSet.get_response_key('a/b/c', "../../answers"))
--     end)

--     it("../.. but prompt key is too short", function()
--         assert.are.same('responses', PromptSet.get_response_key('a', "../.."))
--     end)
-- end)

-- describe("format", function()
--     it("works", function()
--         local entries = {
--             a = {type = 'list'},
--             b = {type = 'prompt', response_key = 'answers'},
--         }

--         PromptSet.format(entries, 'b', entries.b)
--         assert.are.same(
--             {
--                 a = {type = 'list'},
--                 b = {
--                     type = 'prompt',
--                     response_key = 'b/answers',
--                     fields = {open = true}
--                 },
--                 ['b/answers'] = {
--                     type = 'response',
--                     fields = {pinned = false},
--                     prompt_key = 'b',
--                 },
--             },
--             entries
--         )
--     end)
-- end)

-- describe("response_entry_set", function()
--     it("works", function()
--         setup_entry_sets()
--         assert.are.same(response, prompt:response_entry_set())
--     end)
-- end)

-- describe("respond", function()
--     it("works", function()
--         setup_entry_sets()
--         prompt:respond(test_prompt_1)
--         assert.are.same(
--             {date = os.date("%Y%m%d"), pinned = false},
--             response:get_metadata(test_response_1_2)
--         )
--     end)
-- end)

-- describe("responses", function()
--     it("works", function()
--         setup_entry_sets()

--         local input_to_expected = {
--             [test_prompt_1] = {test_response_1_1, test_response_1_2},
--             [test_prompt_2] = {test_response_2_1, test_response_2_2},
--         }
--         for input, expected in pairs(input_to_expected) do
--             local actual = prompt:responses(input)
--             table.sort(actual)
--             table.sort(expected)
--             assert.are.same(expected, actual)
--         end
--     end)
-- end)

-- describe("response", function()
--     it("all", function()
--         setup_entry_sets()
--         response:new_entry(test_response_1_1)
--         response:set_metadata(test_response_1_1, {date = Path.stem(test_response_1_1)})
--         response:new_entry(test_response_1_2)
--         response:set_metadata(test_response_1_2, {pinned = true, date = Path.stem(test_response_1_2)})

--         local expected = {test_response_1_1, test_response_1_2}
--         local actual = prompt:response(test_prompt_1, true)
--         table.sort(expected)
--         table.sort(actual)
--         assert.are.same(expected, actual)
--     end)

--     it("!all", function()
--         setup_entry_sets()
--         response:new_entry(test_response_1_1)
--         response:set_metadata(test_response_1_1, {date = Path.stem(test_response_1_1)})
--         response:new_entry(test_response_1_2)
--         response:set_metadata(test_response_1_2, {pinned = true, date = Path.stem(test_response_1_2)})
--         assert.are.same({test_response_1_2}, prompt:response(test_prompt_1))
--     end)
-- end)

-- describe("move", function()
--     local test_prompt_1_moved = Path.joinpath(test_prompt_dir, 'p1-moved.md')

--     local test_response_1_dir_moved = Path.joinpath(test_response_dir, "p1-moved")
--     local test_response_1_1_moved = Path.joinpath(test_response_1_dir_moved, "20230101.md")
--     local test_response_1_2_moved = Path.joinpath(test_response_1_dir_moved, os.date("%Y%m%d") .. ".md")

--     it("works", function()
--         setup_entry_sets()

--         local old = {
--             test_prompt_1,
--             test_response_1_dir,
--             test_response_1_1,
--             test_response_1_2,
--         }

--         local new = {
--             test_prompt_1_moved,
--             test_response_1_dir_moved,
--             test_response_1_1_moved,
--             test_response_1_2_moved,
--         }

--         for _, path in ipairs(old) do
--             assert(Path.exists(path))
--         end

--         for _, path in ipairs(new) do
--             assert.falsy(Path.exists(path))
--         end

--         prompt:move(test_prompt_1, test_prompt_1_moved)

--         for _, path in ipairs(old) do
--             assert.falsy(Path.exists(path))
--         end

--         for _, path in ipairs(new) do
--             assert(Path.exists(path))
--         end
--     end)
-- end)

-- describe("remove", function()
--     it("works", function()
--         setup_entry_sets()
--         local paths = {
--             test_prompt_1,
--             test_response_1_dir,
--             test_response_1_1,
--             test_response_1_2,
--         }

--         for _, path in ipairs(paths) do
--             assert(Path.exists(path))
--         end

--         prompt:remove(test_prompt_1)

--         for _, path in ipairs(paths) do
--             assert.falsy(Path.exists(path))
--         end
--     end)
-- end)
