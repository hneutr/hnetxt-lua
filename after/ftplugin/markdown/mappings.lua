local Fold = require("htn.ui.fold")

local args = {silent = true, buffer = true}

local mappings = Dict(
    {
        n = Dict({
            ["<c-p>"] = Fold.jump_to_header(-1),
            ["<c-n>"] = Fold.jump_to_header(1),
        }),
        v = Dict({}),
        i = Dict({}),
    },
    require("htn.text.list").toggle_mappings()
)

if vim.b.htn_project then
    local Fuzzy = require("htn.ui.fuzzy")
    local ui = require("htn.ui")

    -- fuzzy
    mappings.n["<leader>df"] = Fuzzy.goto
    mappings.n["<c-/>"] = Fuzzy.put
    mappings.i["<c-/>"] = Fuzzy.insert

    -- scratch
    mappings.n["<leader>s"] = ui.scratch_map_fn
    mappings.v["<leader>s"] = ui.scratch_map_visual_cmd

    -- url opening
    mappings.n["<M-l>"] = ui.goto_map_fn("vsplit")
    mappings.n["<M-j>"] = ui.goto_map_fn("split")
    mappings.n["<M-e>"] = ui.goto_map_fn("edit")
    mappings.n["<M-t>"] = ui.goto_map_fn("tabedit")

    -- mirrors
    mappings.n:update(ui.mirror_mappings())
end

mappings:foreach(function(mode, mode_mappings)
    mode_mappings:foreach(function(rhs, lhs)
        vim.keymap.set(mode, rhs, lhs, args)
    end)
end)
