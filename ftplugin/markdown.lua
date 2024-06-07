local ui = require("htn.ui")

vim.opt_local.autoindent = false
vim.opt_local.cindent = false
vim.opt_local.textwidth = 0
vim.opt_local.shiftwidth = 2

-----------------------------------[ folds ]------------------------------------
vim.opt_local.foldnestmax = 20
vim.opt_local.foldlevel = 19
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldtext = ""
vim.opt_local.foldexpr = 'hnetxt_nvim#foldexpr()'
vim.opt_local.fillchars = {
    fold = " ",
    foldclose = "⋮",
}
vim.opt_local.foldminlines = 0
vim.opt_local.foldenable = true

--------------------------------------------------------------------------------
--                               project stuff                                --
--------------------------------------------------------------------------------
ui.start()

if not vim.g.htn_au_group then
    vim.g.htn_au_group = vim.api.nvim_create_augroup("htn_au_group", {clear = true})
    
    List({
        {
            events = {'VimEnter', 'BufWinEnter', 'WinEnter'},
            callback = ui.enter,
        },
        {
            events = {'TextChanged', "InsertLeave"},
            callback = ui.change,
        },
        {
            events = {'VimLeavePre', 'BufLeave', 'BufWinLeave', 'BufLeave'},
            callback = ui.leave,
        }
    }):foreach(function(autocommand)
        vim.api.nvim_create_autocmd(
            autocommand.events,
            {pattern = "*.md", group = vim.g.htn_au_group, callback = autocommand.callback}
        )
    end)
end

local commands = Dict({
    Journal = function() require("htl.journal")():open() end,
    Aim = function() require("htl.goals")():open() end,
    Track = DB.Log.ui.cmd,
})

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  testing                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Url_cmds = {
    set = {
        run = function(url, args)
            local field, value = unpack(args)
            DB.urls:update({
                where = {id = url.id},
                set = {[field] = value},
            })
        end,
        complete = {"created", "label"},
    },
    get = {
        run = function(url, args)
            local field = args:pop(1)
            print(url[field])
        end,
        complete = {"created", "label", "project"},
    },
}

commands.Url = {
    function(opts)
        local args = List(opts.fargs)

        local key = args:pop(1)
        local cmd = Url_cmds[key]

        if cmd then
            local url = DB.urls:get_file(Path.this())
            if url then
                cmd.run(url, args)
            end
        else
            vim.notify("Url: Unknown command: " .. key, vim.log.levels.ERROR)
        end
    end,
    {
        nargs = "+",
        desc = "get/set a DB.Url field",
        complete = function(lead, line)
            local parts = line:gsub("^Url[!]*%s", "", 1):strip():split()

            local list
            if #parts == 1 then
                list = Dict.keys(Url_cmds)
            elseif #parts == 2 then
                local cmd = Url_cmds[parts[1]] or {}
                list = cmd.complete
                lead = parts[2]
            end
            
            if list then
                return List(list):filter(function(item)
                    return item:startswith(lead)
                end)
            end
        end,
    },
}

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                end testing                                 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
commands:foreach(function(name, cmd)
    local opts
    if type(cmd) == "table" then
        cmd, opts = unpack(cmd)
    end
    vim.api.nvim_buf_create_user_command(0, name, cmd, opts or {})
end)
