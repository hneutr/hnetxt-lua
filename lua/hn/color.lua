local List = require("hl.list")

local mocha = require("catppuccin.palettes").get_palette("mocha")
local macchiato = require("catppuccin.palettes").get_palette("macchiato")

local M = {}

M.C = macchiato

function M.add_to_syntax(key, args)
    local cmd = List({
        "syn match",
        key,
        "/" .. args.string .. "/",
        "containedin=ALL"
    }):join(" ")

    vim.cmd(cmd)
    M.set_highlight({name = key, val = {fg = args.color}})
end

function M.set_highlight(args)
    args = _G.default_args(args, {namespace = 0, name = '', val = {}})

    local allowed_keys = {
        'fg',
        'bg',
        'sp',
        'bold',
        'standout',
        'underline',
        'undercurl',
        'underdouble',
        'underdotted',
        'underdashed',
        'strikethrough',
        'italic',
        'reverse',
        'link',
    }
    local val = {}

    for _, key in ipairs(allowed_keys) do
        val[key] = args.val[key]
    end

    for _, key in ipairs({'fg', 'bg'}) do
        if val[key] ~= nil then
            val[key] = M.C[val[key]]
        end
    end

    if args.name then
        vim.api.nvim_set_hl(args.namespace, args.name, val)
    end
end

return M
