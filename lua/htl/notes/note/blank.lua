local class = require("pl.class")
local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local File = require("htl.notes.note.file")
local Fields = require("htl.notes.field")

class.Blank(File)
Blank.type = 'Blank'

function Blank:write(metadata, content)
    Path.write(self.path, content or "")
end

function Blank:read()
    local metadata, content = {}, ""

    if Path.exists(self.path) then
        content = Path.read(self.path)
    end

    return {metadata, content}
end

function Blank:get_blurb()
    return self:get_stem():gsub("-", " ")
end

function Blank:set_metadata() return end
function Blank:remove_metadata() return end
function Blank:move_metadata() return end
function Blank:flatten_metadata() return end
function Blank:get_filtered_metadata() return {} end
function Blank:meets_filters() return true end

return Blank
