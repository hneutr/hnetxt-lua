local group = vim.api.nvim_create_augroup('markdown_settings', {clear = true})
local pattern = "*.md"

vim.api.nvim_create_autocmd(
    {"BufEnter"},
    {
        pattern=pattern,
        group=group,
        callback=function()
            vim.bo.autoindent = false
            vim.bo.cindent = false
            
            if vim.b.hnetxt_project_root then
                local Path = require("hl.Path")
                local project_spellfile = Path(vim.b.hnetxt_project_root):join(".spell", "en.utf-8.add")
                project_spellfile:parent():mkdir()
                vim.bo.spellfile = vim.bo.spellfile .. "," .. tostring(project_spellfile)
            end
        end,
    }
)
