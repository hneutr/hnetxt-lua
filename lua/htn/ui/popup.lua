local ui = require("htn.ui")
local Heading = require("htl.text.Heading")

local M = {}

M.ui_elements = List({
    "container",
    "prompt",
    "choices",
    "input",
})

M.opts = {
    keymap = {
        ["<C-c>"] = "close",

        ["<C-n>"] = "cursor_down",
        ["<C-p>"] = "cursor_up",
        ["<Down>"] = "cursor_down",
        ["<Up>"] = "cursor_up",

        ["<C-f>"] = "cursor_page_down",
        ["<C-b>"] = "cursor_page_up",

        ["<CR>"] = "goto_selection",

        ["<C-l>"] = "enter_selection",
        ["<C-h>"] = "enter_parent",
        ["<C-r>"] = "enter_root",

        ["<C-1>"] = "filter_h1",
        ["<C-2>"] = "filter_h2",
        ["<C-3>"] = "filter_h3",
        ["<C-4>"] = "filter_h4",
        ["<C-5>"] = "filter_h5",
        ["<C-6>"] = "filter_h6",
    },
    prompt = "> ",
    max_level = 6,
    window = {
        width = 80,
        border = {"╭", "─", "╮", "│", "┤", "─", "├", "│"},
    },
}

function M.open(nearest)
    local state = M.get_state(nearest)

    M.ui_elements:foreach(function(key)
        M[key].attach(state)
    end)

    vim.cmd.startinsert()
end

function M.update(state)
    List.foreach({"prompt", "choices", "input"}, function(key)
        M[key].update(state)
    end)
end

function M.get_actions(state)
    local actions = Dict()

    actions.close = function()
        M.ui_elements:clone():reverse():foreach(function(key)
            vim.api.nvim_win_close(state.ui[key].window, true)
            vim.api.nvim_buf_delete(state.ui[key].buffer, {force = true})
        end)

        vim.fn.win_gotoid(state.source.window)
        vim.api.nvim_input("<esc>")
    end

    actions.cursor_down = function() M.choices.set_cursor(state, 1) end
    actions.cursor_up = function() M.choices.set_cursor(state, -1) end

    actions.cursor_page_down = function() M.choices.set_cursor(state, state.ui.choices.pagesize) end
    actions.cursor_page_up = function() M.choices.set_cursor(state, -state.ui.choices.pagesize) end

    actions.goto_selection = function()
        actions.close()
        ui.set_cursor({row = state.subelements[state.cursor].line})
    end

    actions.enter_selection = function()
        state.parent = state.subelements[state.cursor].index
        state.cursor = 1
        M.update(state)
    end

    actions.enter_parent = function()
        if state.parent and state.parent ~= 0 then
            local parents = state.elements[state.parent].parents
            state.parent = parents[#parents]
            M.update(state)
        end
    end

    actions.enter_root = function()
        state.parent = 0
        M.update(state)
    end

    for level = 1, M.opts.max_level do
        actions[string.format("filter_h%d", level)] = function()
            state.level = state.level ~= level and level or M.opts.max_level
            M.update(state)
        end
    end

    return actions
end

function M.get_state(nearest)
    return {
        source = {
            buffer = vim.api.nvim_get_current_buf(),
            window = vim.fn.win_getid(),
        },
        level = M.opts.max_level,
        cursor = 1,
        parent = 0,
        ui = Dict(),
        nearest = nearest and ui.get_cursor().row,
        elements = ui.ts.headings.get_elements(),
    }
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                 container                                  --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.container = {}

function M.container.attach(state)
    local n_rows = vim.go.lines
    local height = math.floor(n_rows / 2)

    local row = math.floor((n_rows - height) / 2)

    local n_cols = vim.go.columns
    local col = math.floor((n_cols - M.opts.window.width) / 2 - 1)

    state.ui.container = {
        buffer = vim.api.nvim_create_buf(false, true),
    }

	state.ui.container.window = vim.api.nvim_open_win(
        state.ui.container.buffer,
        true,
        {
            relative = "editor",
            width = M.opts.window.width,
            height = height,
            row = row,
            col = col,
            border = "rounded",
            style = "minimal",
            noautocmd = true,
        }
    )
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   prompt                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.prompt = {}

function M.prompt.get_title(state)
    return string.format(
        " %s ",
        state.parent and state.parent ~= 0 and state.elements[state.parent].str or "headings"
    )
end

function M.prompt.attach(state)
    state.ui.prompt = {
        buffer = vim.api.nvim_create_buf(false, true),
        namespace = vim.api.nvim_create_namespace("htn.popup.prompt"),
    }

	state.ui.prompt.window = vim.api.nvim_open_win(
        state.ui.prompt.buffer,
        true, {
            relative = "win",
            win = state.ui.container.window,
            width = M.opts.window.width,
            height = 1,
            row = -2,
            col = -1,
            title = M.prompt.get_title(state),
            title_pos = "center",
            border = M.opts.window.border,
            noautocmd = true,
            style = "minimal",
        }
    )

    M.prompt.update(state)
end

function M.prompt.get_line(state)
    local line = M.opts.prompt

    if state.level < M.opts.max_level then
        line = string.format("[%d] %s", state.level, line)
    end

    return line
end

function M.prompt.set_title(state)
    local u = state.ui.prompt

    local conf = vim.api.nvim_win_get_config(u.window)
    local title = M.prompt.get_title(state)

    if conf.title ~= title then
        conf.title = title
        vim.api.nvim_win_set_config(u.window, conf)
    end
end

function M.prompt.set_line(state)
    local u = state.ui.prompt

	vim.api.nvim_buf_set_lines(u.buffer, 0, 1, true, {M.prompt.get_line(state)})

	vim.api.nvim_buf_clear_namespace(u.buffer, u.namespace, 0, -1)

    if state.level then
        vim.api.nvim_buf_add_highlight(
            u.buffer,
            u.namespace,
            Heading.get_level(state.level).hl_group,
            0,
            1,
            2
        )
    end
end

function M.prompt.update(state)
    M.prompt.set_title(state)
    M.prompt.set_line(state)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  choices                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.choices = {}

function M.choices.attach(state)
    state.ui.choices = {
        buffer = vim.api.nvim_create_buf(false, true),
        namespaces = Dict({
            cursor = vim.api.nvim_create_namespace("htn.popup.cursor"),
            element = vim.api.nvim_create_namespace("htn.popup.element"),
        }),
        height = vim.api.nvim_win_get_config(state.ui.container.window).height - 1,
    }

    state.ui.choices.pagesize = math.floor(state.ui.choices.height / 2)

	state.ui.choices.window = vim.api.nvim_open_win(
        state.ui.choices.buffer,
        true,
        {
            relative = "win",
            win = state.ui.container.window,
            width = M.opts.window.width,
            height = state.ui.choices.height,
            row = 1,
            col = 0,
            style = "minimal",
            noautocmd = true,
        }
    )

    M.choices.update(state)
end

function M.choices.filter(state)
    if state.nearest then
        local line = state.nearest
        state.nearest = false
        state.elements:foreach(function(e) state.parent = e.line <= line and e.index or state.parent end)
    end

    state.parent = state.parent or 0
    state.pattern = ui.get_cursor_line():lower()

    state.subelements = state.elements:filter(function(e)
        local result = true
        result = result and e.parents:contains(state.parent)
        result = result and e.level.n <= state.level

        if #state.pattern > 0 then
            result = result and e.text:lower():match(state.pattern)
        end
        return result
    end)
end

function M.choices.set_lines(state)
    local levels = #state.subelements > 0 and state.subelements:map(function(e) return e.level.n end)
    local min_level = math.min(unpack(levels or {0}))

    local u = state.ui.choices
	vim.api.nvim_buf_set_lines(
        u.buffer,
        0,
        -1,
        true,
        state.subelements:map(function(e)
            return string.format(
                "%s%s",
                string.rep("  ", e.level.n - min_level),
                e.text
            ):rpad(M.opts.window.width, " ")
        end)
    )

    vim.api.nvim_buf_clear_namespace(u.buffer, u.namespaces.element, 0, -1)

    for i, element in ipairs(state.subelements) do
        vim.api.nvim_buf_add_highlight(
            u.buffer,
            u.namespaces.element,
            element.level.hl_group,
            i - 1,
            0,
            -1
        )
    end
end

function M.choices.set_cursor(state, delta)
    state.cursor = state.cursor + (delta or 0)
    state.cursor = math.min(state.cursor, #state.subelements)
    state.cursor = math.max(state.cursor, 1)

    local u = state.ui.choices
    vim.api.nvim_buf_clear_namespace(u.buffer, u.namespaces.cursor, 0, -1)

    if #state.subelements > 0 then
        vim.api.nvim_buf_add_highlight(
            u.buffer,
            u.namespaces.cursor,
            state.subelements[state.cursor].level.bg_hl_group,
            state.cursor - 1,
            0,
            -1
        )
    end
end

function M.choices.update(state)
    M.choices.filter(state)

    M.choices.set_lines(state)
    M.choices.set_cursor(state)

    M.prompt.set_title(state)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   input                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
M.input = {}

function M.input.attach(state)
    state.ui.input = {
        buffer = vim.api.nvim_create_buf(false, true),
    }

    local col = M.input.get_col(state)

	state.ui.input.window = vim.api.nvim_open_win(
        state.ui.input.buffer,
        true,
        {
            relative = "win",
            win = state.ui.prompt.window,
            width = M.opts.window.width - col,
            height = 1,
            row = 0,
            col = col,
            noautocmd = true,
            style = "minimal",
        }
    )

    local actions = M.get_actions(state)

    Dict.foreach(M.opts.keymap, function(lhs, key)
	    vim.keymap.set("i", lhs, actions[key], {silent = true, buffer = true})
    end)

	vim.api.nvim_create_autocmd(
        "TextChangedI",
        {
            callback = function() M.update(state) end,
            buffer = state.ui.input.buffer,
        }
    )

	vim.api.nvim_create_autocmd(
        "InsertLeave",
        {
            callback = actions.close,
            buffer = state.ui.input.buffer,
            once = true,
        }
    )
end

function M.input.get_col(state)
    return #M.prompt.get_line(state)
end

function M.input.update(state)
    local conf = vim.api.nvim_win_get_config(state.ui.input.window)
    local col = M.input.get_col(state)

    if conf.col ~= col then
        conf.col = col
        conf.width = M.opts.window.width - col
        vim.api.nvim_win_set_config(state.ui.input.window, conf)
    end
end

return M
