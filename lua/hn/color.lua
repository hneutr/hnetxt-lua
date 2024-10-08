local M = {}

M.C = require("catppuccin.palettes").get_palette("macchiato")

M.valid_keys = Set({
    'fg',
    'bg',
    'sp',
    'bold',
    'blend',
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
})

function M.get_hl_attr(group, attr)
    attr = attr or "fg"
    return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), attr)
end

function M.add_to_syntax(key, args)
    if args.string and not args.cmd then
        args.cmd = List({
            "syn match",
            key,
            "/" .. args.string .. "/",
            "containedin=ALL"
        }):join(" ")

    end
    
    if args.cmd then
        vim.cmd(args.cmd)
    end

    local style = Dict(args.val or {fg = args.color})

    style = style:filterk(function(k) return M.valid_keys:has(k) end)
    
    List({'fg', 'bg', 'sp'}):foreach(function(k)
        style[k] = style[k] and M.C[style[k]] or nil
    end)
    
    vim.api.nvim_set_hl(0, key, style)
end

return M
