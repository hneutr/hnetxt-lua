local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require('hl.Path')
local ui = require("htn.ui")

local BufferLines = require("hn.buffer_lines")

local ui = require("htn.ui")
local Fold = require('htn.ui.fold')

local commands = Dict({
    Journal = function() require("htl.journal")():open() end,
    Aim = function() require("htl.goals")():open() end,
    Track = DB.Log.ui.cmd,
    SetDate = {function(args) DB.urls:set_date(Path.this(), args.args) end, {nargs = 1}},
    PrintDate = function() print(DB.urls:where({path = Path.this()}).created) end,
})

local autocommands = Dict()

vim.b.htn_mirror_prefix = "<leader>o"

vim.opt_local.autoindent = false
vim.opt_local.cindent = false
vim.opt_local.textwidth = 0
vim.opt_local.shiftwidth = 2

-----------------------------------[ folds ]------------------------------------
vim.opt_local.foldnestmax = 20
vim.opt_local.foldlevel = 19
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'hnetxt_nvim#foldexpr()'
vim.opt_local.foldtext = "hnetxt_nvim#foldtext()"
vim.opt_local.fillchars = {fold = " "}
vim.opt_local.foldminlines = 0
vim.opt_local.foldenable = true

autocommands.htn_fold = List({
    {
        events = {'TextChanged', 'InsertLeave'},
        callback=Fold.set_line_info,
    }
})

--------------------------------------------------------------------------------
--                               project stuff                                --
--------------------------------------------------------------------------------
local current_file = Path.this()
local project = DB.projects.get_by_path(current_file)

if project then
    vim.opt_local.spellfile:append(ui.spellfile(project.path))
    
    project.path = tostring(project.path)
    vim.b.htn_project = project

    ui.set_file_url(current_file)

    autocommands.htn_link_update = List({
        {
            events = {'VimEnter', 'WinEnter', 'BufEnter', 'VimLeave', 'WinLeave', 'BufLeave'},
            callback = ui.update_link_urls,
        }
    })

    -- commands.FileToLink = ui.FileToLink
    -- commands.LinkToFile = ui.LinkToFile
end

autocommands.htn_statusline = List({
    {
        events = {'VimEnter', 'WinEnter', "BufEnter", 'BufWinEnter'},
        callback = function()
            vim.opt_local.statusline = ui.get_statusline()
        end,
    }
})


autocommands.htn_link_update = List({
    {
        events = {'VimLeave', 'WinLeave', 'BufLeave'},
        callback = function()
            ui.save_metadata(current_file)
        end
    }
})


commands:foreach(function(name, cmd)
    local opts
    if type(cmd) == "table" then
        cmd, opts = unpack(cmd)
    end
    vim.api.nvim_buf_create_user_command(0, name, cmd, opts or {})
end)

autocommands:keys():foreach(function(group_name)
    local group = vim.api.nvim_create_augroup(group_name, {clear = true})
    autocommands[group_name]:foreach(function(autocommand)
        vim.api.nvim_create_autocmd(
            autocommand.events,
            {pattern = "*.md", group = group, callback = autocommand.callback}
        )
    end)
end)
