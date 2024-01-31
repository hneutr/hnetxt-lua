local Path = require('hn.path')
local db = require("htl.db")
local Fold = require('htn.ui.fold')

local pattern = "*.md"

vim.b.hnetxt_opener_prefix = "<leader>o"

vim.opt_local.autoindent = false
vim.opt_local.cindent = false
vim.opt_local.textwidth = 0
vim.opt_local.shiftwidth = 2

--------------------------------------------------------------------------------
--                               project stuff                                --
--------------------------------------------------------------------------------
local current_file = Path(Path.current_file())
local project = db.get()['projects'].get_by_path(current_file)

if project then
    local project_root = project.path

    -- spellfile
    local project_spellfile = project_root:join(".spell", "en.utf-8.add")
    project_spellfile:parent():mkdir()

    vim.opt_local.spellfile:append(tostring(project_spellfile))

    -- statusline
    if current_file:is_relative_to(project_root) then
        vim.opt_local.statusline = tostring(current_file:relative_to(project_root))
    end

    project.path = tostring(project.path)
    vim.b.hnetxt_project_root = project.path
    vim.b.htn_project = project

    if db.get()['mirrors']:is_source(current_file) then
        db.get()['urls']:add_if_missing(current_file)
    end
end

--------------------------------------------------------------------------------
--                                   folds                                    --
--------------------------------------------------------------------------------
vim.opt_local.foldnestmax = 20
vim.opt_local.foldlevel = 19
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'hnetxt_nvim#foldexpr()'
vim.opt_local.foldtext = "hnetxt_nvim#foldtext()"
vim.opt_local.fillchars = {fold = " "}
vim.opt_local.foldminlines = 0
vim.opt_local.foldenable = true

vim.api.nvim_create_autocmd(
    {'TextChanged', 'InsertLeave'},
    {
        pattern=pattern,
        group=vim.api.nvim_create_augroup('htn-fold', {clear = true}),
        callback=Fold.set_line_info,
    }
)

------------------------------------[ sync ]------------------------------------
local Sync = require('htn.project.sync')
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
