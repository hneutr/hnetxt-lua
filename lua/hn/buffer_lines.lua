local M = {}

--------------------------------------------------------------------------------
--                              generic line ops                              --
--------------------------------------------------------------------------------
function M._do(args)
    local a = Dict(args or {}, {
        action = nil,
        buffer = 0,
        start_line = 0,
        end_line = vim.fn.line('$'), 
        strict_indexing = false,
        replacement = {},
    })

    if a.action == 'get' then
        return vim.api.nvim_buf_get_lines(a.buffer, a.start_line, a.end_line, a.strict_indexing)
    elseif a.action == 'set' then
        return vim.api.nvim_buf_set_lines(a.buffer, a.start_line, a.end_line, a.strict_indexing, a.replacement)
    end
end

function M.get(args)
    return M._do(Dict(args or {}, {action = 'get'}))
end

function M.set(args)
    return M._do(Dict(args or {}, {action = 'set'}))
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
    return M.set(M.selection._set_range(args))
end

return M
