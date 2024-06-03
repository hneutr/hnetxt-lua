local M = {}

--------------------------------------------------------------------------------
--                              generic line ops                              --
--------------------------------------------------------------------------------
function M._do(args)
    local l = List({
        args.buffer or 0,
        args.start_line or 0,
        args.end_line or vim.fn.line('$'),
        args.strict_indexing or false,
    })

    if args.action == 'get' then
        return List(vim.api.nvim_buf_get_lines(unpack(l)))
    elseif args.action == 'set' then
        l:append(args.replacement or {})
        vim.api.nvim_buf_set_lines(unpack(l))
    end
end

function M.get(args)
    return M._do(Dict(args or {}, {action = 'get'}))
end

function M.set(args)
    M._do(Dict(args or {}, {action = 'set'}))
end

--------------------------------------------------------------------------------
--                                 selections                                 --
--------------------------------------------------------------------------------
M.selection = {}

function M.selection.range(args)
    args = args or {}
    local mode = args.mode or 'n'
    local buffer = args.buffer or 0

    local start_line, end_line

    if mode == 'n' then
        start_line = vim.api.nvim_win_get_cursor(buffer)[1] - 1
        end_line = start_line + 1
    elseif mode == 'v' then
        vim.api.nvim_input('<esc>')
        start_line = vim.api.nvim_buf_get_mark(buffer, '<')[1] - 1
        end_line = vim.api.nvim_buf_get_mark(buffer, '>')[1]
        
        if start_line < 0 then
            start_line = 0
        end
    end

    return {start_line = start_line, end_line = end_line}
end

function M.selection._set_range(args)
    return Dict(args or {}, M.selection.range(args))
end

function M.selection.get(args)
    return M.get(M.selection._set_range(args))
end

function M.selection.set(args)
    M.set(M.selection._set_range(args))
end

return M
