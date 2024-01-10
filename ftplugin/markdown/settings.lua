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
        end,
    }
)
