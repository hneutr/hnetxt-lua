local devicons = require("nvim-web-devicons")

local M = {}

M.views = {}
M.namespace = vim.api.nvim_create_namespace("markview")

M.conf = require("htn.markview.conf")
M.config = M.conf.signs

function M.clear(buffer)
	vim.api.nvim_buf_clear_namespace(buffer, M.namespace, 0, -1)
end

--- Returns a value with the specified inddx from entry
--- If index is nil then return the last value
--- If entry isn't a table then return it
local function tbl_clamp(entry, index)
	if type(entry) ~= "table" then
		return entry
	end

	if index <= #entry then
		return entry[index]
	end

	return entry[#entry]
end

function M.add_hls(usr_hls)
	local hl_list = usr_hls or M.conf.colors

	for _, tbl in ipairs(hl_list) do
		vim.api.nvim_set_hl(0, tbl.group_name, tbl.value)
	end
end

function M.add_extmark(extmark, buffer, row, col)
    vim.api.nvim_buf_set_extmark(
        buffer,
        M.namespace,
        Dict.pop(extmark, 'row') or row,
        Dict.pop(extmark, 'col') or col,
        extmark
    )
end

function M.render_header(buffer, component)
	local conf = tbl_clamp(M.config.header, component.level)
	
	local row = component.row_start
	local col = component.col_start
	local level = component.level
	local pad_char = " "
	
	local extmarks = List()

	if conf.style == "simple" then
	    extmarks:append({
            line_hl_group = conf.line_hl,
            priority = 8,
	    })
	elseif conf.style == "icon" then
	    extmarks:append({
            line_hl_group = conf.line_hl,
            priority = 8,
            virt_text_pos = "overlay",
            virt_text = {
                {
                    pad_char:rep(level - 1),
                    conf.icon_hl
                },
                {
                    conf.icon,
                    conf.icon_hl
                }
            }
	    })
	elseif conf.style == "padded_icon" then
	    extmarks:append({
	        col = col + level + vim.fn.strchars(conf.icon) - 1,
            virt_text_pos = "inline",
            virt_text = {
                {
                    pad_char,
                    conf.icon_hl
                },
            }
	    })

		local icon_width = conf.icon_width or vim.fn.strchars(conf.icon)
		
		extmarks:append({
            line_hl_group = conf.line_hl,
            priority = 8,
            virt_text_pos = "overlay",
            virt_text = {
                {
                    pad_char:rep(col + level - icon_width < 0 and 0 or col + level - icon_width),
                    conf.icon_hl
                },
                {
                    conf.icon,
                    conf.icon_hl
                }
            }
		})
	end
	
	extmarks:foreach(M.add_extmark, buffer, row, col)
end

function M.render_code_block(buffer, component)
	local conf = M.config.code_block

	local row = component.row_start
	local col = component.col_start

	local pad_char = " "
	local lang_virt_pad = pad_char:rep(3 + vim.fn.strchars(component.language))
	
	local extmarks = List()

	if conf.style == "simple" then
	    extmarks:append({
            virt_text_pos = "overlay",
            virt_text = {{lang_virt_pad, conf.block_hl}}
        })

        extmarks:append({
            row = row + 1,
            end_row = component.row_end - 2,
            end_col = component.col_end,
            line_hl_group = conf.block_hl
        })

        extmarks:append({
            row = component.row_end - 1,
            virt_text_pos = "overlay",
            virt_text = {{lang_virt_pad, conf.block_hl}},
            line_hl_group = conf.block_hl
        })
	elseif conf.style == "padded" then
        extmarks:append({
            virt_text_pos = "overlay",
            virt_text = {{lang_virt_pad, conf.block_hl}},
            line_hl_group = conf.block_hl
        })

		for line = 1, component.row_end - component.row_start - 1 do
		    extmarks:append({
                row = row + line,
                virt_text_pos = "inline",
                virt_text = {
                    {
                        pad_char,
                        conf.block_hl
                    }
                },
                line_hl_group = conf.block_hl
		    })
		end

        extmarks:append({
            row = component.row_end - 1,
            virt_text_pos = "overlay",
            virt_text = {{lang_virt_pad, conf.block_hl}},
            line_hl_group = conf.block_hl
        })

	elseif conf.style == "language" then
		local icon, hl = devicons.get_icon(nil, component.language, { default = true })
		local pad_len = 3 - vim.fn.strchars(icon .. " ")

        extmarks:append({
            virt_text_pos = "overlay",
            virt_text = {
                {icon .. " ", hl},
                {component.language, conf.language_hl or hl},
                {string.rep(" ", pad_len)}
            },
            line_hl_group = conf.block_hl
        })

		for line = 1, component.row_end - row - 1 do
		    extmarks:append({
		        row = row + line,
                virt_text_pos = "inline",
                virt_text = {{"", conf.block_hl}},
                line_hl_group = conf.block_hl
            })
		end

        extmarks:append({
            row = component.row_end - 1,
            virt_text_pos = "overlay",
            virt_text = {{lang_virt_pad, conf.block_hl}},
            line_hl_group = conf.block_hl
        })
	end

	extmarks:foreach(M.add_extmark, buffer, row, col)
end

function M.render_block_quote(buffer, component)
	local conf

	local row = component.row_start
	local col = component.col_start

	if component.callout ~= nil then
		for _, callout in ipairs(M.config.block_quote.callouts) do
			if callout.match_string == component.callout then
				conf = callout

				break
			end
		end

		if conf == nil then
			conf = M.config.block_quote.default
		end
	else
		conf = M.config.block_quote.default
	end

    local extmarks = List()
	if conf.callout_preview ~= nil then
	    extmarks:append({
			virt_text_pos = "overlay",
			virt_text = {
				{tbl_clamp(conf.border, 1), tbl_clamp(conf.border_hl, 1)},
				{conf.callout_preview, conf.callout_preview_hl}
			}
	    })
	else
	    extmarks:append({
			virt_text_pos = "overlay",
			virt_text = {
				{tbl_clamp(conf.border, 1), tbl_clamp(conf.border_hl, 1)},
			}
	    })
	end

	for line = 1, component.row_end - row - 1 do
	    extmarks:append({
	        row = row + line,
			virt_text_pos = "overlay",
			virt_text = {{tbl_clamp(conf.border, line + 1), tbl_clamp(conf.border_hl, line + 1)}}
	    })
	end

	extmarks:foreach(M.add_extmark, buffer, row, col)
end

function M.render_horizontal_rule(buffer, component)
	local conf = M.config.horizontal_rule

    M.add_extmark(
        {
			virt_text_pos = "overlay",
			virt_text = {{conf.border_char:rep(vim.o.columns), conf.border_hl}}
        },
        buffer,
        component.row_start,
        component.col_start
    )
end

function M.render_hyperlink(buffer, component)
	local conf = M.config.hyperlink
	
	M.add_extmark(
	    {
            virt_text_pos = "inline",
            virt_text = {{(conf.icon or "") .. component.link_text, conf.hl}},
            conceal = "",
            end_row = component.row_end,
            end_col = component.col_end
	    },
        buffer,
        component.row_start,
        component.col_start
	)
end

function M.render_img_link(buffer, component)
	local conf = M.config.image

	M.add_extmark(
	    {
            virt_text_pos = "inline",
            virt_text = {{(conf.icon or "") .. component.link_text, conf.hl}},
            conceal = "",
            end_row = component.row_end,
            end_col = component.col_end
	    },
        buffer,
        component.row_start,
        component.col_start
	)
end

-- TODO: clean below here
function M.render_inline_code(buffer, component)
	local conf = M.config.inline_code

	M.add_extmark(
	    {
            virt_text_pos = "inline",
            virt_text = {
                {conf.before, conf.hl},
                {component.text, conf.hl},
                {conf.after, conf.hl},
            },
            end_row = component.row_end,
            end_col = component.col_end
	    },
        buffer,
        component.row_start,
        component.col_start
	)
end

function M.render_list(buffer, component)
	local conf = {}
	
	local marker = component.mark_symbol

	if string.match(marker, "-") then
		conf = M.config.list_item.marker_minus or {}
	elseif string.match(marker, "+") then
		conf = M.config.list_item.marker_plus or {}
	elseif string.match(marker, "*") then
		conf = M.config.list_item.marker_star or {}
	end

	if conf.add_padding == true then
		local shiftwidth = vim.bo[buffer].shiftwidth or 4

		for i = 0, (component.row_end - component.row_start) - 1 do
			local line = vim.api.nvim_buf_get_lines(buffer, component.row_start + i, component.row_start + i + 1, false)[1]

			--- BUG: Sometimes the marker is wider then 2 characters so we add the extra spaces to align it property
			vim.api.nvim_buf_set_extmark(buffer, M.namespace, component.row_start + i, 0, {
				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(" ", shiftwidth - component.col_start - (vim.fn.strchars(component.marker_symbol) - 2)), "Normal" }
				},

				hl_mode = "combine"
			})

			if i ~= 0 and vim.fn.strchars(line) > component.col_start then
				vim.api.nvim_buf_set_extmark(buffer, M.namespace, component.row_start + i, component.col_start, {
					virt_text_pos = "overlay",
					virt_text = {
						{ string.rep(" ", 2), "Normal" }
					},

					hl_mode = "combine"
				})
			end
		end
	else
		for i = 1, (component.row_end - component.row_start) - 1 do
			local line = vim.api.nvim_buf_get_lines(buffer, component.row_start + i, component.row_start + i + 1, false)[1]

			if vim.fn.strchars(line) > component.col_start then
				vim.api.nvim_buf_set_extmark(buffer, M.namespace, component.row_start + i, component.col_start, {
					virt_text_pos = "overlay",
					virt_text = {
						{ string.rep(" ", 2), "Normal" }
					},

					hl_mode = "combine"
				})
			end
		end
	end

	if conf.marker ~= nil then
		--- BUG: Sometimes the marker is wider then 2 characters so we change the position of the marker to align it property
		if vim.fn.strchars(component.marker_symbol) > 2 then
			vim.api.nvim_buf_set_extmark(buffer, M.namespace, component.row_start, component.col_start + (vim.fn.strchars(component.marker_symbol) - 2), {
				virt_text_pos = "overlay",
				virt_text = {
					{ conf.marker, conf.marker_hl }
				}
			})
		else
			vim.api.nvim_buf_set_extmark(buffer, M.namespace, component.row_start, component.col_start, {
				virt_text_pos = "overlay",
				virt_text = {
					{ conf.marker, conf.marker_hl }
				}
			})
		end
	end
end

function M.render_checkbox(buffer, component)
	local conf = M.config.checkbox

	if component.checked == true then
		vim.api.nvim_buf_set_extmark(buffer, M.namespace, component.row_start, component.col_start, {
			virt_text_pos = "overlay",
			virt_text = {
				{ conf.checked.marker, conf.checked.marker_hl }
			}
		})
	elseif component.checked == false then
		vim.api.nvim_buf_set_extmark(buffer, M.namespace, component.row_start, component.col_start, {
			virt_text_pos = "overlay",
			virt_text = {
				{ conf.unchecked.marker, conf.unchecked.marker_hl }
			}
		})
	end
end

function M.render(buffer)
	local view = M.views[buffer]

	if view == nil then
		return
	end

	for _, extmark in ipairs(view) do
		local fold_closed = vim.fn.foldclosed(extmark.row_start + 1)

		if fold_closed ~= -1 then
			goto extmark_skipped
		end

		if extmark.type == "header" then
			M.render_header(buffer, extmark)
		elseif extmark.type == "code_block" then
			M.render_code_block(buffer, extmark)
		elseif extmark.type == "block_quote" then
			M.render_block_quote(buffer, extmark)
		elseif extmark.type == "horizontal_rule" then
			M.render_horizontal_rule(buffer, extmark)
		elseif extmark.type == "hyperlink" then
			M.render_hyperlink(buffer, extmark)
		elseif extmark.type == "image" then
			M.render_img_link(buffer, extmark)
		elseif extmark.type == "inline_code" then
			M.render_inline_code(buffer, extmark)
		elseif extmark.type == "list_item" then
			M.render_list(buffer, extmark)
		elseif extmark.type == "checkbox" then
			M.render_checkbox(buffer, extmark)
		end

		::extmark_skipped::
	end
end

return M
