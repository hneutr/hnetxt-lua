local Fold = require("htn.ui.fold")
local ui = require("htn.ui")

local args = {silent = true, buffer = true}

local mappings = Dict(
    {
        n = Dict({
            ["<c-p>"] = Fold.jump_to_header(-1),
            ["<c-n>"] = Fold.jump_to_header(1),
            -- url opening
            ["<M-l>"] = ui.goto_map_fn("vsplit"),
            ["<M-j>"] = ui.goto_map_fn("split"),
            ["<M-e>"] = ui.goto_map_fn("edit"),
            ["<M-t>"] = ui.goto_map_fn("tabedit"),
            -- set time
            ["<C-t>"] = ui.set_time,
        }),
        v = Dict(),
        i = Dict(),
    },
    require("htn.text.list").toggle_mappings()
)

if vim.b.htn_project then
    local Fuzzy = require("htn.ui.fuzzy")

    -- fuzzy
    mappings.n["<leader>df"] = Fuzzy.goto
    mappings.n["<C-/>"] = Fuzzy.put
    mappings.i["<C-/>"] = Fuzzy.insert

    -- scratch
    mappings.n["<leader>s"] = ui.scratch_map_fn
    mappings.v["<leader>s"] = ui.scratch_map_visual_cmd

    -- mirrors
    mappings.n:update(ui.mirror_mappings())
    
    -- taxonomy symbols
    mappings.i:update(ui.taxonomy_mappings("<M-t>"))
end

mappings:foreach(function(mode, mode_mappings)
    mode_mappings:foreach(function(rhs, lhs)
        vim.keymap.set(mode, rhs, lhs, args)
    end)
end)
