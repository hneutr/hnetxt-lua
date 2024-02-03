local BufferLines = require("hn.buffer_lines")
local Path = require('hn.path')
local db = require("htl.db")

return function(mode)
    local lines = BufferLines.selection.get({mode = mode})
    BufferLines.selection.cut({mode = mode})

    if lines[#lines] ~= "" then
      table.insert(lines, "")
    end

    local path = db.get()['mirrors']:get_mirror_path(Path.this(), "scratch")

    if Path.exists(path) then
        lines[#lines + 1] = Path.read(path)
    end

    Path.write(path, lines)
end
