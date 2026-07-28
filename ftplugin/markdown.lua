local ui = require("htn.ui")
local commands = require("htn.commands")

-----------------------------------[ folds ]------------------------------------
vim.opt_local.foldnestmax = 20
vim.opt_local.foldlevel = 19
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'hnetxt_nvim#foldexpr()'
vim.opt_local.foldtext = ""
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
            events = {"BufModifiedSet"},
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

commands:foreach(function(name, cmd)
    local opts
    if type(cmd) == "table" then
        cmd, opts = unpack(cmd)
    end
    vim.api.nvim_buf_create_user_command(0, name, cmd, opts or {})
end)
