local List = require("hl.list")
local Dict = require("hl.Dict")
local Path = require('hn.path')

local db = require("htl.db")

local suffix_to_open_cmd = Dict({
    e = 'e',
    o = 'e',
    l = 'vs',
    v = 'vs',
    j = 'sp',
    s = 'sp'
})

return function()
    if not vim.g.htn_mirror_mappings then
        local mappings = Dict()
        db.get().mirrors.configs.generic:foreach(function(kind, conf)
            suffix_to_open_cmd:foreach(function(suffix, open_cmd)
                mappings[vim.b.htn_mirror_prefix .. conf.mapkey .. suffix] = function()
                    Path.open(
                        db.get()['mirrors']:get_mirror_path(Path.this(), kind),
                        open_cmd
                    )
                end
            end)
        end)

        vim.g.htn_mirror_mappings = mappings
    end

    return Dict(vim.g.htn_mirror_mappings)
end
