local ui = require("htn.ui")
local Path = require('hn.path')
local db = require("htl.db")
local Fold = require('htn.ui.fold')

local pattern = "*.md"

vim.b.htn_mirror_prefix = "<leader>o"

vim.opt_local.autoindent = false
vim.opt_local.cindent = false
vim.opt_local.textwidth = 0
vim.opt_local.shiftwidth = 2

--------------------------------------------------------------------------------
--                               project stuff                                --
--------------------------------------------------------------------------------
local current_file = Path.this()
local project = db.get()['projects'].get_by_path(current_file)

if project then
    local project_root = project.path

    -- spellfile
    local project_spellfile = project_root:join(".spell", "en.utf-8.add")
    project_spellfile:parent():mkdir()

    vim.opt_local.spellfile:append(tostring(project_spellfile))

    project.path = tostring(project.path)
    vim.b.hnetxt_project_root = project.path
    vim.b.htn_project = project

    -- statusline
    vim.opt_local.statusline = ui.statusline(current_file, project_root)
    
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
