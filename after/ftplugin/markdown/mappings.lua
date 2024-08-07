local ui = require("htn.ui")

local args = {silent = true, buffer = true}

local mappings = Dict(
    {
        n = Dict({
            -- folds
            zc = ui.fold_operation("zc"),
            zC = ui.fold_operation("zC"),
            zo = ui.fold_operation("zo"),
            zO = ui.fold_operation("zO"),
            za = ui.fold_operation("za"),
            zA = ui.fold_operation("zA"),
            zr = ui.fold_operation("zr"),
            zR = ui.fold_operation("zR"),
            -- zm = ui.fold_operation("zm"),
            -- zM = ui.fold_operation("zM"),

            ["<c-p>"] = ui.jump_to_header(-1),
            ["<c-n>"] = ui.jump_to_header(1),
            -- url opening
            ["<M-l>"] = ui.goto_map_fn("vsplit"),
            ["<M-j>"] = ui.goto_map_fn("split"),
            ["<M-e>"] = ui.goto_map_fn("edit"),
            ["<M-t>"] = ui.goto_map_fn("tabedit"),
            -- set time or calculate quantity
            ["<C-t>"] = ui.set_time_or_calculate_sum,
            -- copy word count at cursor
            ["gG"] = ui.copy_wordcount_to_clipboard,
        }),
        v = Dict(),
        i = Dict(),
    },
    require("htn.text.list").toggle_mappings()
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
