local Path = require("hl.path")
local Entry = require("htl.project.notes.entry")

local ResponseEntry = Entry:extend()
ResponseEntry.type = 'response'
ResponseEntry.default_key = 'responses'
ResponseEntry.default_fields = {pinned = false}
ResponseEntry.iterdir_args = {recursive = true, dirs = false}

function ResponseEntry.get_entry(prompt_key)
    return {
        type = ResponseEntry.type,
        fields = ResponseEntry.default_fields,
        prompt_key = prompt_key,
    }
end

function ResponseEntry:prompt_entry_set()
    return self.entry_sets[self.prompt_key]
end

function ResponseEntry:path(path, date)
    date = date or os.date("%Y%m%d")
    return Path.joinpath(self.entry_set_path, Path.stem(path), date .. ".md")
end

return ResponseEntry
