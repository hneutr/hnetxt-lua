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

            -- sections
            ["<c-p>"] = ui.sections.prev,
            ["<c-n>"] = ui.sections.next,

            -- headings
            ["<C-,>"] = HeadingPopup(),
            ["<C-.>"] = HeadingPopup({nearest = true}),
            ["<C-1>"] = HeadingPopup({level = 1}),
            ["<C-2>"] = HeadingPopup({level = 2}),
            ["<C-3>"] = HeadingPopup({level = 3}),
            ["<C-4>"] = HeadingPopup({level = 4}),
            ["<C-5>"] = HeadingPopup({level = 5}),

            -- misc
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


mappings:foreach(function(mode, mode_mappings)
    mode_mappings:foreach(function(rhs, lhs)
        vim.keymap.set(mode, rhs, lhs, {silent = true, buffer = true})
    end)
end)
