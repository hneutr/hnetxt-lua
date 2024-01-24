local Path = require('hn.path')
local db = require("htl.db")
local Fold = require('htn.ui.fold')
local Sync = require('htn.project.sync')

local pattern = "*.md"

--------------------------------[ project root ]--------------------------------
local project_root = db.get()['projects'].get_path(Path.current_file())

vim.b.hnetxt_opener_prefix = "<leader>o"

if project_root ~= nil then
    vim.b.hnetxt_project_root = tostring(project_root)

    local project_spellfile = project_root:join(".spell", "en.utf-8.add")
    project_spellfile:parent():mkdir()

    vim.b.project_spellfile = tostring(project_spellfile)
end

-----------------------------------[ folds ]------------------------------------
vim.api.nvim_create_autocmd(
    {"VimEnter", "BufEnter"},
    {
        pattern=pattern,
        group=vim.api.nvim_create_augroup('hnetxt_buffer', {clear = true}),
        callback=function()
            vim.opt_local.autoindent = false
            vim.opt_local.cindent = false

            vim.opt_local.textwidth = 0
            vim.opt_local.shiftwidth = 2

            if vim.b.project_spellfile then
                vim.bo.spellfile = vim.bo.spellfile .. "," .. vim.b.project_spellfile
            end

        end
    }
)

vim.api.nvim_create_autocmd(
    {"VimEnter", "WinNew"},
    {
        pattern=pattern,
        group=vim.api.nvim_create_augroup('hnetxt_window', {clear = true}),
        callback=function()
            vim.opt.fillchars = {fold = " "}

            vim.opt.foldmethod = 'expr'
            vim.opt.foldexpr = 'hnetxt_nvim#foldexpr()'
            vim.opt.foldtext = "hnetxt_nvim#foldtext()"
            vim.opt.foldlevel = 19
            vim.opt.foldnestmax = 20
            vim.opt.foldminlines = 0
            vim.opt.foldenable = true
        end
    }
)

vim.api.nvim_create_autocmd(
    {'TextChanged', 'InsertLeave'},
    {
        pattern=pattern,
        group=vim.api.nvim_create_augroup('hnetxt_fold_cmds', {clear = true}),
        callback=Fold.set_line_info,
    }
)

------------------------------------[ sync ]------------------------------------
-- vim.b.hnetxt_sync = true

local group = vim.api.nvim_create_augroup('hnetxt_sync', {clear = true})

vim.api.nvim_create_autocmd(
    {"BufEnter"},
    {pattern=pattern, group=group, callback=Sync.if_active(Sync.buf_enter)}
)

vim.api.nvim_create_autocmd(
    {'TextChanged', 'InsertLeave'},
    {pattern=pattern, group=group, callback=Sync.if_active(Sync.buf_change)}
)

vim.api.nvim_create_autocmd(
    {'BufLeave', 'VimLeave'},
    {pattern=pattern, group=group, callback=Sync.if_active(Sync.buf_leave)}
)
