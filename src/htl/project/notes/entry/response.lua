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

function ResponseEntry:set_metadata(path, metadata)
    metadata = metadata or {}

    local new_date = metadata.date

    if new_date then
        local old_date = self:get_metadata(path).date

        if Path.stem(path) == old_date then
            local old_path = path
            path = Path.with_stem(path, new_date)
            Path.rename(old_path, path)
        end
    end

    self.super.set_metadata(self, path, metadata)
end

function ResponseEntry:move(source, target)
    local metadata = self:get_metadata(source)
    local date = tostring(metadata.date)
    
    local new_date = tonumber(Path.stem(target))

    if date == Path.stem(source) and new_date then
        self.super.set_metadata(self, source, {date = new_date})
    end

    Path.rename(source, target)
end

function ResponseEntry:prompt_entry_set()
    return self.entry_sets[self.prompt_key]
end

function ResponseEntry:path(p, metadata)
    local prompt = self:prompt_for_path(p)

    if Path.exists(prompt) then
        local prompt_response_dir = self:response_dir_for_path(p)

        if prompt_response_dir then
            metadata = metadata or {}
            date = metadata.date or os.date("%Y%m%d")
            return Path.joinpath(prompt_response_dir, date .. ".md")
        end
    end

    return nil
end

function ResponseEntry:pin(path)
    self:set_metadata(path, {pinned = true})
end

function ResponseEntry:unpin(path)
    self:set_metadata(path, {pinned = false})
end

function ResponseEntry:response_dir_for_path(p)
    local prompt_entry_set = self:prompt_entry_set()
    local p = self:prompt_for_path(p)

    if p and Path.exists(p) then
        p = Path.relative_to(p, prompt_entry_set.entry_set_path)

        return Path.joinpath(self.entry_set_path, Path.with_suffix(p, ''))
    end
    return nil
end

function ResponseEntry:prompt_for_path(p)
    local prompt_entry_set = self:prompt_entry_set()

    if Path.is_relative_to(p, self.entry_set_path) then
        p = Path.relative_to(p, self.entry_set_path)

        if #Path.suffix(p) > 0 then
            p = Path.parent(p)
        end

        p = Path.with_suffix(p, ".md")

        return Path.joinpath(prompt_entry_set.entry_set_path, p)
    elseif Path.is_relative_to(p, prompt_entry_set.entry_set_path) then
        return p
    end

    return nil
end

return ResponseEntry
