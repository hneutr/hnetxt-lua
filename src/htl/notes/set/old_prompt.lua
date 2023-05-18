-- table = require('hl.table')
-- string = require("hl.string")
-- local Path = require("hl.path")

-- local FileSet = require("htl.notes.set.file")
-- local ResponseSet = require("htl.notes.set.response")

-- local PromptSet = FileSet:extend()
-- PromptSet.type = 'prompt'
-- PromptSet.default_fields = {open = true}

-- function PromptSet.get_response_key(prompt_key, relative_key)
--     relative_key = relative_key or ''

--     local response_key = prompt_key
    
--     while relative_key:startswith("..") do
--         relative_key = relative_key:removeprefix(".."):removeprefix("/")

--         response_key = Path.parent(response_key) or ''
--     end

--     if #relative_key == 0 then
--         relative_key = ResponseSet.default_key
--     end

--     if #response_key > 0 then
--         response_key = Path.joinpath(response_key, relative_key)
--     else
--         response_key = relative_key
--     end

--     return response_key
-- end

-- function PromptSet.format(sets, key, set)
--     set.response_key = PromptSet.get_response_key(key, set.response_key)
--     set.fields = table.default(PromptSet.default_fields, set.fields or {})

--     sets[set.response_key] = ResponseSet.get_set(key)
--     return sets
-- end

-- function PromptSet:move(source, target)
--     local response_set = self:response_set()
--     local responses_source = response_set:response_dir_for_path(source)

--     Path.rename(source, target)

--     local responses_target = response_set:response_dir_for_path(target)

--     Path.rename(responses_source, responses_target)
-- end

-- function PromptSet:remove(path)
--     local response_set = self:response_set()

--     Path.rmdir(response_set:response_dir_for_path(path), true)
--     Path.unlink(path)
-- end

-- function PromptSet:response_set()
--     return self.sets[self.response_key]
-- end

-- function PromptSet:respond(path)
--     local response_set = self:response_set()
--     local path = Path.joinpath(response_set:response_dir_for_path(path), os.date("%Y%m%d") .. ".md")
--     response_set:touch(path)
-- end

-- function PromptSet:responses(path)
--     local response_set = self:response_set()
--     local prompt_responses_dir = response_set:response_dir_for_path(path)

--     local responses = {}
--     for _, response in ipairs(response_set:paths()) do
--         if Path.parent(response) == prompt_responses_dir then
--             table.insert(responses, response)
--         end
--     end

--     return responses
-- end

-- function PromptSet:response(path, all)
--     local responses = self:responses(path)
--     local pinned_responses = {}

--     for _, response in ipairs(responses) do
--         local metadata = self:get_metadata(response)
--         if metadata.pinned then
--             table.insert(pinned_responses, response)
--         end
--     end

--     if #pinned_responses == 0 or all then
--         return responses
--     end

--     return pinned_responses
-- end

-- return PromptSet
