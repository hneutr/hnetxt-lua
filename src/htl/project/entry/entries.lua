table = require('hl.table')
local Object = require("hl.object")

local Fields = require("htl.project.entry.fields")

local Entry = require("htl.project.entry")
local PromptEntry
local ResponseEntry
local ListEntry

local Entries = {}

Entries.classes = {
    PromptEntry,
    ResponseEntry,
    ListEntry,
    Entry,
}

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

    entry.fields = Fields.format(fields)

    return entry
end

function Entries.get_entry_class(args)
    for _, class in ipairs(Entries.classes) do
        if args.type == class.type or class.is_of_type(args) then
            return class
        end
    end

    return Entry
end

return Entries
