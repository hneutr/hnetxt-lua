local M = {}
local renderer = require("htn.markview.renderer")

function M.md(buffer, TStree)
    local scanned_queies = vim.treesitter.query.parse("markdown", [[
        (atx_heading [
            (atx_h1_marker)
            (atx_h2_marker)
            (atx_h3_marker)
            (atx_h4_marker)
            (atx_h5_marker)
            (atx_h6_marker)
        ] @header)

        ((fenced_code_block) @code)

        ((block_quote) @block_quote)

        ((thematic_break) @horizontal_rule)

        ;((task_list_marker_unchecked) @checkbox_off)
        ;((task_list_marker_checked) @checkbox_on)

        ;((list_item) @list_item)
    ]])

	-- The last 2 _ represent the metadata & query
    for capture_id, capture_node, _, _ in scanned_queies:iter_captures(TStree:root()) do
        local capture_name = scanned_queies.captures[capture_id]
        local capture_text = vim.treesitter.get_node_text(capture_node, buffer)
        local row_start, col_start, row_end, col_end = capture_node:range()

        if capture_name == "header" then
            table.insert(renderer.views[buffer], {
                type = "header",
                level = vim.fn.strchars(capture_text),

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        elseif capture_name == "code" then
            table.insert(renderer.views[buffer], {
                type = "code_block",
                language = vim.treesitter.get_node_text(capture_node:named_child(1), buffer),

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        elseif capture_name == "block_quote" then
            table.insert(renderer.views[buffer], {
                type = "block_quote",

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        elseif capture_name == "horizontal_rule" then
            table.insert(renderer.views[buffer], {
                type = "horizontal_rule",

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        elseif capture_name == "list_item" then
            local marker = capture_node:named_child(0)

            table.insert(renderer.views[buffer], {
                type = "list_item",
                marker_symbol = vim.treesitter.get_node_text(marker, buffer),

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        elseif capture_name == "checkbox_off" then
            table.insert(renderer.views[buffer], {
                type = "checkbox",
                checked = false,

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        elseif capture_name == "checkbox_on" then
            table.insert(renderer.views[buffer], {
                type = "checkbox",
                checked = true,

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        end
    end
end

function M.md_inline(buffer, TStree)
    local scanned_queies = vim.treesitter.query.parse("markdown_inline", [[
        ((shortcut_link) @callout)

        ((inline_link) @link)

        ((image) @image)

        ((code_span) @code)
    ]])

    -- The last 2 _ represent the metadata & query
    for capture_id, capture_node, _, _ in scanned_queies:iter_captures(TStree:root()) do
        local capture_name = scanned_queies.captures[capture_id]
        local capture_text = vim.treesitter.get_node_text(capture_node, buffer)
        local row_start, col_start, row_end, col_end = capture_node:range()

        if capture_name == "callout" then
            for _, extmark in ipairs(renderer.views[buffer]) do
                if extmark.type == "block_quote" and extmark.row_start == row_start then
                    extmark.callout = capture_text
                end
            end
        elseif capture_name == "link" then
            local link_text = string.match(capture_text, "%[(.-)%]")
            local link_address = string.match(capture_text, "%((.-)%)")

            table.insert(renderer.views[buffer], {
                type = "hyperlink",

                link_text = link_text,
                link_address = link_address,

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        elseif capture_name == "image" then
            local link_text = string.match(capture_text, "%[(.-)%]")
            local link_address = string.match(capture_text, "%((.-)%)")

            table.insert(renderer.views[buffer], {
                type = "image",

                link_text = link_text,
                link_address = link_address,

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        elseif capture_name == "code" then
            table.insert(renderer.views[buffer], {
                type = "inline_code",

                text = string.gsub(capture_text, "`", ""),

                row_start = row_start,
                row_end = row_end,

                col_start = col_start,
                col_end = col_end
            })
        end
    end
end

--- Initializes the parsers on the specified buffer
--- Parsed data is stored as a "view" in renderer.lua
function M.init(buffer)
	local root_parser = vim.treesitter.get_parser(buffer)
	root_parser:parse(true)

	renderer.views[buffer] = {}

	root_parser:for_each_tree(function (TStree, language_tree)
		local tree_language = language_tree:lang()

		if tree_language == "markdown" then
			M.md(buffer, TStree)
		elseif tree_language == "markdown_inline" then
			M.md_inline(buffer, TStree)
		end
	end)
end

return M
