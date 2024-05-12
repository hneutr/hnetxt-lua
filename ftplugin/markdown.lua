local ui = require("htn.ui")
local Fold = require('htn.ui.fold')

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

--------------------------------------------------------------------------------
--                               project stuff                                --
--------------------------------------------------------------------------------
local current_file = Path.this()
local project = DB.projects.get_by_path(current_file)

if project then
    vim.opt_local.spellfile:append(ui.spellfile(project.title))
    
    project.path = tostring(project.path)
    vim.b.htn_project = project

    ui.set_file_url(current_file)
end

if not vim.g.setup_htn then
    local event_to_nvim_events = Dict({
        change = {'TextChanged', "InsertLeave"},
        enter = {'VimEnter', 'BufWinEnter', 'WinEnter'},
        leave = {'VimLeavePre', 'BufWinLeave'},
    })

    local autocommands = DefaultDict(List)

    autocommands.enter:append(function() vim.opt_local.statusline = ui.get_statusline() end)
    autocommands.enter:append(function() vim.b.htn_modified = false end)
    autocommands.change:append(function() vim.b.htn_modified = true end)
    autocommands.change:append(Fold.set_line_info)
    autocommands.leave:append(ui.update_link_urls)
    autocommands.leave:append(ui.save_metadata)

    autocommands:foreach(function(event_key, callbacks)
        local group = vim.api.nvim_create_augroup("htn_" .. event_key, {clear = true})
        callbacks:foreach(function(callback)
            vim.api.nvim_create_autocmd(
                event_to_nvim_events[event_key],
                {pattern = "*.md", group = group, callback = callback}
            )
        end)
    end)

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
end

vim.g.setup_htn = true
