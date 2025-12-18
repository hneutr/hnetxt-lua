local ui = require("htn.ui")
local HeadingPopup = require("htn.popup.headings")
local UrlsPopup = require("htn.popup.urls")
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

            -- headings
            ["<C-.>"] = HeadingPopup(),
            ["<C-,>"] = HeadingPopup({localize = true}),
            ["<C-1>"] = HeadingPopup({level = 1}),
            ["<C-2>"] = HeadingPopup({level = 2}),
            ["<C-3>"] = HeadingPopup({level = 3}),
            ["<C-4>"] = HeadingPopup({level = 4}),
            ["<C-5>"] = HeadingPopup({level = 5}),
            ["<C-6>"] = HeadingPopup({level = 6}),
            ["<C-m>"] = HeadingPopup({todo = true}),

            -- misc
            ["<leader>n"] = ui.open_record_for_today,
            ["<C-/>"] = UrlsPopup(),
            ["<C-\\>"] = UrlsPopup({global = false}),
            ["<C-t>"] = ui.set_time_or_calculate_sum,
            ["gG"] = ui.copy_wordcount,
        }),
        i = Dict({
            -- continue lists
            ["<cr>"] = TextList.continue,

            -- symbols
            ["<M-i>"] = require("htn.popup.symbols"),

            -- url insert
            ["<C-/>"] = UrlsPopup(),
        }),
        v = Dict(),
        nv = Dict({
            -- sections
            ["<c-p>"] = ui.sections.prev,
            ["<c-n>"] = ui.sections.next,

        }),
    },
    require("htn.text.list").mappings()
)

if vim.b.htn_project_path then
    -- scratch
    mappings.n["<leader>s"] = ui.scratch
    mappings.v["<leader>s"] = ui.scratch_map_visual_cmd

    -- mirrors
    mappings.n:update(ui.mirror_mappings())
end

mappings:foreach(function(modes, mode_mappings)
    mode_mappings:foreach(function(rhs, lhs)
        vim.keymap.set(List(modes), rhs, lhs, {silent = true, buffer = true})
    end)
end)
