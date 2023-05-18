-- local Path = require("hl.path")
-- local FileSet = require("htl.notes.set.file")

-- local ResponseSet = FileSet:extend()
-- ResponseSet.type = 'response'
-- ResponseSet.default_key = 'responses'
-- ResponseSet.default_fields = {pinned = false}
-- ResponseSet.iterdir_args = {recursive = true, dirs = false}

-- function ResponseSet.get_set(prompt_key)
--     return {
--         type = ResponseSet.type,
--         fields = ResponseSet.default_fields,
--         prompt_key = prompt_key,
--     }
-- end

-- function ResponseSet:set_metadata(path, metadata)
--     metadata = metadata or {}

--     local new_date = metadata.date

--     if new_date then
--         local old_date = self:get_metadata(path).date

--         if Path.stem(path) == old_date then
--             local old_path = path
--             path = Path.with_stem(path, new_date)
--             Path.rename(old_path, path)
--         end
--     end

--     self.super.set_metadata(self, path, metadata)
-- end

-- function ResponseSet:move(source, target)
--     local metadata = self:get_metadata(source)
--     local date = tostring(metadata.date)
    
--     local new_date = tonumber(Path.stem(target))

--     if date == Path.stem(source) and new_date then
--         self.super.set_metadata(self, source, {date = new_date})
--     end

--     Path.rename(source, target)
-- end

-- function ResponseSet:prompt_set()
--     return self.sets[self.prompt_key]
-- end

-- function ResponseSet:response_dir_for_path(p)
--     local prompt_set = self:prompt_set()
--     local p = self:prompt_for_path(p)

--     if p and Path.exists(p) then
--         p = Path.relative_to(p, prompt_set.path)

--         return Path.joinpath(self.path, Path.with_suffix(p, ''))
--     end
--     return nil
-- end

-- function ResponseSet:prompt_for_path(p)
--     local prompt_set = self:prompt_set()

--     if Path.is_relative_to(p, self.path) then
--         p = Path.relative_to(p, self.path)

--         if #Path.suffix(p) > 0 then
--             p = Path.parent(p)
--         end

--         p = Path.with_suffix(p, ".md")

--         return Path.joinpath(prompt_set.path, p)
--     elseif Path.is_relative_to(p, prompt_set.path) then
--         return p
--     end

--     return nil
-- end

-- return ResponseSet
