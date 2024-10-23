local ui = require("htn.ui")
local Heading = require("htl.text.Heading")
-- local fzy = require("telescope.algos.fzy")

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
    level_default = 6,
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

function M.move_cursor(state, delta)
    local cursor = state.cursor + delta
    cursor = math.min(cursor, #state.subelements)
    cursor = math.max(cursor, 1)

    state.cursor = cursor
    M.choices.highlight_cursor(state)
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

    actions.cursor_down = function() M.move_cursor(state, 1) end
    actions.cursor_up = function() M.move_cursor(state, -1) end

    actions.cursor_page_down = function() M.move_cursor(state, state.ui.choices.pagesize) end
    actions.cursor_page_up = function() M.move_cursor(state, -state.ui.choices.pagesize) end

    actions.goto_selection = function()
        local element = state.subelements[state.cursor]
        actions.close()
        ui.set_cursor({row = element.line})
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

    for level = 1, M.opts.level_default do
        actions[string.format("filter_h%d", level)] = function()
            state.level = state.level ~= level and level or M.opts.level_default
            M.update(state)
        end
    end

    return actions
end

function M.close()
end

function M.get_state(nearest)
    Store.heading_popup = Store.heading_popup or List()

    local buffer = vim.api.nvim_get_current_buf()
    local state = Store.heading_popup[buffer] or Dict()

    state.elements = ui.ts.headings.get_raw({node = ui.ts.get_root(), buffer = buffer})
    state.source = {
        buffer = buffer,
        window = vim.fn.win_getid(),
    }
    state.level = M.opts.level_default
    state.cursor = 1
    state.ui = state.ui or Dict()
    state.parent = nil

    if nearest then
        state.nearest = ui.get_cursor().row
    end

    M.set_parents(state.elements)

    Store.heading_popup[buffer] = state

    return state
end

function M.set_parents(elements)
    local level_to_parent = List({0, 0, 0, 0, 0, 0})
    for i, element in ipairs(elements) do
        local level = element.level.n

        element.n_children = 0
        element.parents = Set(level_to_parent:slice(1, level)):vals()
        element.index = i

        for j = level + 1, M.opts.level_default do
            level_to_parent[j] = i
        end
    end
end

function M.update_ui(state)
    M.ui_elements:foreach(function(key)
        M[key].update(state)
    end)
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

    local signcol_n = 1 + #tostring(math.max(
        vim.fn.winheight(0),
        vim.fn.line("$")
    ))
    local n_cols = vim.go.columns
    local col = math.floor((n_cols - M.opts.window.width) / 2 - 1)
    -- local col = math.floor((n_cols - M.opts.window.width - signcol_n) / 2)

    state.ui.container = {
        buffer = vim.api.nvim_create_buf(false, true),
        namespaces = Dict(),
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
        namespaces = Dict({
            prompt = vim.api.nvim_create_namespace("htn.popup.prompt"),
        })
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

    M.prompt.update(state, state.ui)
end

function M.prompt.get_line(state)
    local line = M.opts.prompt

    local level = state.level

    if level < M.opts.level_default then
        line = string.format(
            "[%d] %s",
            level,
            line
        )
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

function M.prompt.update(state)
    local u = state.ui.prompt

    M.prompt.set_title(state)

	vim.api.nvim_buf_set_lines(u.buffer, 0, 1, true, {M.prompt.get_line(state)})

	vim.api.nvim_buf_clear_namespace(u.buffer, u.namespaces.prompt, 0, -1)

    if state.level then
        vim.api.nvim_buf_add_highlight(
            u.buffer,
            u.namespaces.prompt,
            Heading.get_level(state.level).hl_group,
            0,
            1,
            2
        )
    end
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
    state.parent = state.parent or 0

    local results = List()
    state.subelements = state.elements:filter(function(e)
        local result = true
        result = result and e.parents:contains(state.parent)
        result = result and e.level.n <= state.level

        if state.pattern and #state.pattern > 0 then
            result = result and e.text:lower():match(state.pattern)
            -- result = result and (fzy.score(state.pattern, e.text) > 0)
        end
        return result
    end)

    if #state.subelements then
        state.min_element_level = math.min(unpack(state.subelements:map(function(e) return e.level.n end)))
    else
        state.min_element_level = 0
    end
    state.cursor = math.min(state.cursor, #state.subelements)
end

function M.choices.format_element(element, state)
    return string.format(
        "%s%s",
        string.rep("  ", element.level.n - state.min_element_level),
        element.text
    )
end

function M.choices.highlight_elements(state)
    local u = state.ui.choices
    vim.api.nvim_buf_clear_namespace(u.buffer, u.namespaces.element, 0, -1)

    for i, subelement in ipairs(state.subelements) do
        vim.api.nvim_buf_add_highlight(
            u.buffer,
            u.namespaces.element,
            subelement.level.hl_group,
            i - 1,
            0,
            -1
        )
    end
end

function M.choices.highlight_cursor(state)
    local u = state.ui.choices
    vim.api.nvim_buf_clear_namespace(u.buffer, u.namespaces.cursor, 0, -1)

    vim.api.nvim_buf_add_highlight(
        u.buffer,
        u.namespaces.cursor,
        state.subelements[state.cursor].level.bg_hl_group,
        state.cursor - 1,
        0,
        -1
    )
end

function M.choices.handle_nearest(state)
    if state.nearest then
        local line = state.nearest
        state.nearest = false

        for i, element in ipairs(state.elements) do
            if state.elements[i].line <= line then
                state.parent = i
            end
        end
    end
end

function M.choices.update(state)
    M.choices.handle_nearest(state)
    M.choices.filter(state)

    local u = state.ui.choices

	vim.api.nvim_buf_set_lines(
        u.buffer,
        0,
        -1,
        true,
        state.subelements:map(M.choices.format_element, state)
    )

    M.prompt.set_title(state)
    M.choices.highlight_elements(state)
    M.choices.highlight_cursor(state)
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
        namespaces = Dict(),
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

	vim.api.nvim_create_autocmd(
        "TextChangedI",
        {
            callback = function()
                state.pattern = ui.get_cursor_line():lower()
                M.update(state)
            end,
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

    M.input.set_keymap(actions)
end

function M.input.set_keymap(actions)
    Dict.foreach(M.opts.keymap, function(lhs, key)
	    vim.keymap.set(
            "i",
            lhs,
            actions[key],
            {
                silent = true,
                buffer = true,
            }
        )
    end)
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
