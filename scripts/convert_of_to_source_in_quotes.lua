local Path = require("hl.Path")
local Yaml = require("hl.yaml")
local Link = require("htl.text.link")

local old_quotes_dir = Path.home:join('Documents', 'text', '_quotes')
local eidola_dir = Path.home:join("eidola")
local people_dir = eidola_dir:join("people")
local media_dir = eidola_dir:join("media")

media_dir:glob("%.md$"):foreach(function(p)
    local text = Yaml.read_raw_text(p) or ""

    if #text:strip() == 0 and p:stem() ~= "@" and p:read():match("is a: quote") then
        p:unlink()
    end
end)
