local ui = require("htn.ui")

local M = Dict({
    Journal = function() require("htl.journal")():open() end,
    Aim = function() require("htl.goals")():open() end,
    Track = DB.Log.ui.cmd,
})

M.Url = {
    function(opts)
        local args = List(opts.fargs)

        local field = args:pop(1)
        local fields = Set({"created", "label", "project", "modified"})
        
        if not fields:has(field) then
            vim.notify("Url: Unknown field: " .. field, vim.log.levels.ERROR)
        end

        local path = Path.this()
        ui.set_file_url(path)

        local url = DB.urls:get_file(path)

        if not url then
            vim.notify("Url: untracked file", vim.log.levels.ERROR)
        end

        if #args == 0 then
            print(url[field])
        elseif field == "project" then
            vim.notify("Url: can't set project", vim.log.levels.ERROR)
        else
            DB.urls:update({
                where = {id = url.id},
                set = {[field] = args:join(" ")},
            })
        end
    end,
    {
        nargs = "+",
        desc = "get/set a DB.Url field",
        complete = function(lead)
            return List({"created", "label", "project", "modified"}):filter(function(field)
                return field:startswith(lead)
            end)
        end,
    },
}

M.Ety = {
    function(opts)
        local args = List(opts.fargs)
        
        local word
        if #args == 0 then
            local url = DB.urls:where({path = Path.this(), type = "file"})
            
            if url then
                word = url.label
            end
        else
            word = args:pop(1)
        end

        if word then
            local ety = require("htl.ety")
            ety.open({word = word})
        end
    end,
    {
        nargs = "?",
        desc = "open etymonline to the word",
    },
}

return M
