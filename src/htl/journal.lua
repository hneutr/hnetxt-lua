local mirrors = require("htl.db.mirrors")

return function()
    local path = Conf.paths.journals_dir / string.format("%s.md", os.date("%Y%m%d"))
    
    path:touch()
    DB.urls:insert({path = path})

    local metadata_path = mirrors:get_path(path, "metadata")

    local is_a_line = "is a: journal entry"
    local has_is_a_line = false
    
    local metadata_lines = metadata_path:exists() and metadata_path:readlines() or List()
    
    metadata_lines:foreach(function(l) has_is_a_line = has_is_a_line or l == is_a_line end)
    
    if not has_is_a_line then
        metadata_lines:put(is_a_line)
        metadata_path:write(metadata_lines)
    end

    return path
end
