require("hl.string")

local Path = require("hl.Path")
local lyaml = require("lyaml")
local utils = require("hl.utils")

local M = {}

M.load = lyaml.load
M.matter_sep = "\n\n"

function M.dump(matter)
    local str = lyaml.dump({matter}):removeprefix("---\n"):removesuffix("...\n")
    return str
end

function M.write(path, matter)
    Path(path):write(M.dump(matter))
end

function M.read(path)
    return utils.typify(M.load(Path(path):read()))
end

function M.write_document(path, matter, text)
    text = text or ''
    text = type(text) == "table" and List.join(text, "\n") or text

    text = text:lstrip()
    text = #text == 0 and "\n" or text

    Path(path):write(M.dump(matter):rstrip() .. M.matter_sep .. text)
end

function M.read_document(path, raw)
    local matter, text = unpack(Path(path):read():split(M.matter_sep, 1))
    return {raw and matter or M.load(matter), (text or ''):strip()}
end

return M
