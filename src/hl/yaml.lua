require("hl.string")

local Path = require("hl.Path")
local lyaml = require("lyaml")

local M = {}

M.load = lyaml.load
M.document_frontmatter_separator = "\n\n"

function M.dump(frontmatter_table)
    local str = lyaml.dump({frontmatter_table})
    str = str:removeprefix("---\n")
    str = str:removesuffix("...\n")
    return str
end

function M.write(path, frontmatter_table)
    Path(path):write(M.dump(frontmatter_table))
end

function M.read(path)
    return M.load(Path(path):read())
end

function M.write_document(path, frontmatter_table, text)
    local frontmatter_str = M.dump(frontmatter_table):rstrip()

    text = text or ''
    text = type(text) == "table" and List.join(text, "\n") or text

    text = text:lstrip()

    if #text == 0 then
        text = "\n"
    end

    local content = frontmatter_str .. M.document_frontmatter_separator .. text

    Path(path):write(content)
end

function M.read_document(path, raw)
    local contents = Path(path):read()
    local frontmatter, text = unpack(contents:split(M.document_frontmatter_separator, 1))
    text = text or ''

    if raw ~= true then
        frontmatter = M.load(frontmatter)
    end

    return {frontmatter, text:strip()}
end

function M.read_raw_frontmatter(path)
    local contents = Path(path):read()
    local frontmatter_str, _ = unpack(contents:split(M.document_frontmatter_separator, 1))
    return frontmatter_str:split("\n")
end

function M.read_raw_text(path)
    local contents = Path(path):read()
    return contents:split(M.document_frontmatter_separator, 1)[2]
end

return M
