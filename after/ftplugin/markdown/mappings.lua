local ui = require("htn.ui")
local HeadingPopup = require("htn.ui.popup")
local TextList = require("htn.text.list")

local mappings = Dict(
    {
        n = Dict({
            -- remove list characters when joining lines
            J = TextList.join,

            -- add a line below the current one
            o = TextList.add_line,

            -- url opening
            ["<M-l>"] = ui.goto_map_fn("vsplit"),
            ["<M-j>"] = ui.goto_map_fn("split"),
            ["<M-e>"] = ui.goto_map_fn("edit"),
            ["<M-t>"] = ui.goto_map_fn("tabedit"),

            -- sections
            ["<c-p>"] = ui.sections.prev,
            ["<c-n>"] = ui.sections.next,

            -- headings
            ["<C-,>"] = HeadingPopup.open_all,
            ["<C-.>"] = HeadingPopup.open_nearest,
            ["<C-i>"] = ui.headings.toggle_inclusion,

            -- misc
            ["<C-t>"] = ui.set_time_or_calculate_sum,
            ["gG"] = ui.copy_wordcount,
        }),
        i = Dict({
            -- continue lists
            ["<cr>"] = TextList.continue,

            -- symbols
            ["<M-i>"] = require("htn.ui.symbols_popup"),
        }),
        v = Dict(),
    },
    require("htn.text.list").mappings()
)

if vim.b.htn_project_path then
    -- fuzzy
    mappings.n["<leader>df"] = ui.map_fuzzy("goto")
    mappings.n["<C-/>"] = ui.map_fuzzy("put")
    mappings.i["<C-/>"] = ui.map_fuzzy("insert")

    mappings.n["<leader>dF"] = ui.map_fuzzy("goto", "global")
    mappings.n["<C-\\>"] = ui.map_fuzzy("put", "global")
    mappings.i["<C-\\>"] = ui.map_fuzzy("insert", "global")

    -- scratch
    mappings.n["<leader>s"] = ui.scratch
    mappings.v["<leader>s"] = ui.scratch_map_visual_cmd

    -- mirrors
    mappings.n:update(ui.mirror_mappings())
end

mappings:foreach(function(mode, mode_mappings)
    mode_mappings:foreach(function(rhs, lhs)
        vim.keymap.set(mode, rhs, lhs, {silent = true, buffer = true})
    end)
end)
