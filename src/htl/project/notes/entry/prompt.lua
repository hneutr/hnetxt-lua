table = require('hl.table')
string = require("hl.string")
local Path = require("hl.path")

local Entry = require("htl.project.notes.entry")
local ResponseEntry = require("htl.project.notes.entry.response")

local PromptEntry = Entry:extend()
PromptEntry.type = 'prompt'
PromptEntry.default_fields = {open = true}

function PromptEntry.get_response_key(prompt_key, relative_key)
    relative_key = relative_key or ''

    local response_key = prompt_key
    
    while relative_key:startswith("..") do
        relative_key = relative_key:removeprefix(".."):removeprefix("/")

        response_key = Path.parent(response_key) or ''
    end

    if #relative_key == 0 then
        relative_key = ResponseEntry.default_key
    end

    if #response_key > 0 then
        response_key = Path.joinpath(response_key, relative_key)
    else
        response_key = relative_key
    end

    return response_key
end

function PromptEntry.format(entries, key, entry)
    entry.response_key = PromptEntry.get_response_key(key, entry.response_key)
    entry.fields = table.default(PromptEntry.default_fields, entry.fields or {})

    entries[entry.response_key] = ResponseEntry.get_entry(key)
    return entries
end

function PromptEntry:move(source, target)
    local response_entry_set = self:response_entry_set()
    local responses_source = response_entry_set:response_dir_for_path(source)

    Path.rename(source, target)

    local responses_target = response_entry_set:response_dir_for_path(target)

    Path.rename(responses_source, responses_target)
end

function PromptEntry:remove(path)
    local response_entry_set = self:response_entry_set()

    Path.rmdir(response_entry_set:response_dir_for_path(path), true)
    Path.unlink(path)
end

function PromptEntry:response_entry_set()
    return self.entry_sets[self.response_key]
end

function PromptEntry:respond(path)
    local response_entry_set = self:response_entry_set()
    local path = Path.joinpath(response_entry_set:response_dir_for_path(path), os.date("%Y%m%d") .. ".md")
    response_entry_set:new_entry(path)
end

function PromptEntry:responses(path)
    local response_entry_set = self:response_entry_set()
    local prompt_responses_dir = response_entry_set:response_dir_for_path(path)

    local responses = {}
    for _, response in ipairs(response_entry_set:paths()) do
        if Path.parent(response) == prompt_responses_dir then
            table.insert(responses, response)
        end
    end

    return responses
end

function PromptEntry:response(path, all)
    local responses = self:responses(path)
    local pinned_responses = {}

    for _, response in ipairs(responses) do
        local metadata = self:get_metadata(response)
        if metadata.pinned then
            table.insert(pinned_responses, response)
        end
    end

    if #pinned_responses == 0 or all then
        return responses
    end

    return pinned_responses
end

return PromptEntry
