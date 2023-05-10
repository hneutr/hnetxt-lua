table = require('hl.table')
local Path = require("hl.path")
local Object = require("hl.object")

local Fields = require("htl.project.notes.fields")

local Entry = require("htl.project.notes.entry")
local PromptEntry = require("htl.project.notes.entry.prompt")
local ResponseEntry = require("htl.project.notes.entry.response")
local ListEntry = require("htl.project.notes.entry.list")

local Entries = {}

Entries.by_type = {
    [PromptEntry.type] = PromptEntry,
    [ResponseEntry.type] = ResponseEntry,
    [ListEntry.type] = ListEntry,
    [Entry.type] = Entry,
}

function Entries.get_class(entry)
    return Entries.by_type[entry.type or Entry.type]
end

function Entries.format_config(config)
    local entries = Entries.flatten(Entries.format(config).entries)
    
    for key, entry in pairs(entries) do
        Entries.get_class(entry).format(entries, key, entry)
    end

    for key, entry in pairs(entries) do
        entry.fields = Fields.format(entry.fields)
    end

    return entries
end

function Entries.flatten(entries)
    entries = entries or {}
    for key, entry in pairs(entries) do
        entries[key] = entry

        for subkey, subentry in pairs(Entries.flatten(entry.entries)) do
            subkey = Path.joinpath(key, subkey)
            entries[subkey] = subentry
        end

        entries[key].entries = nil
    end

    return entries
end

function Entries.format(entry)
    entry = entry or {}

    local entries = entry.entries or {}
    if table.is_list(entries) then
        for i, key in ipairs(entries) do
            entries[key] = {}
            entries[i] = nil
        end
    end

    local fields = entry.fields or {}
    for key, subentry in pairs(entries) do
        subentry = subentry or {}
        subentry.fields = table.default(subentry.fields, fields)

        entries[key] = Entries.format(subentry)
    end

    if #table.keys(entries) > 0 then
        entry.entries = entries
    else
        entry.entries = nil
    end

    return entry
end

return Entries
