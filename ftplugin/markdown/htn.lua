local ui = require("htn.ui")
local Path = require('hn.path')
local db = require("htl.db")
local Fold = require('htn.ui.fold')
local BufferLines = require("hn.buffer_lines")
local List = require("hl.List")

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
    vim.opt_local.spellfile:append(ui.spellfile(project.path))
    vim.opt_local.statusline = ui.statusline(current_file, project.path)
    
    project.path = tostring(project.path)
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

--------------------------------------------------------------------------------
--                                link updates                                --
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd(
    {'VimEnter', 'WinEnter', 'BufEnter', 'VimLeave', 'WinLeave', 'BufLeave'},
    {
        pattern=pattern,
        group=vim.api.nvim_create_augroup('htn-link-update', {clear = true}),
        callback=function()
            db.get().urls:update_link_urls(Path.this(), List(BufferLines.get()))
        end,
    }
)

