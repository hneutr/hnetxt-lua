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
    SetDate = {function(args) DB.urls:set_date(Path.this(), args.args) end, {nargs = 1}},
    PrintDate = function() print(DB.urls:where({path = Path.this()}).created) end,
})

commands:foreach(function(name, cmd)
    local opts
    if type(cmd) == "table" then
        cmd, opts = unpack(cmd)
    end
    vim.api.nvim_buf_create_user_command(0, name, cmd, opts or {})
end)
