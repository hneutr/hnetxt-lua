local M = {}
local parser = require("htn.markview.parser")
local renderer = require("htn.markview.renderer")

M.options_set = {}

M.setup = function (user_config)
	renderer.config = vim.tbl_deep_extend("keep", user_config or {}, renderer.config)

	if renderer.config.highlight_groups ~= false then
		renderer.add_hls(renderer.config.highlight_groups)
	end

	vim.api.nvim_create_autocmd({"BufWinEnter"}, {
		pattern = "*.md",
		callback = function (event)
			local windows = vim.api.nvim_list_wins()

			-- Check for windows that have this buffer and set the necessary options in them
			for _, window in ipairs(windows) do
				local buf = vim.api.nvim_win_get_buf(window)

				-- Do not set options if the options are already set
				if vim.list_contains(M.options_set, window) == false and buf == event.buf then
					vim.wo[window].conceallevel = 2
					vim.wo[window].concealcursor = "nc"

					table.insert(M.options_set, window)
				end
			end

			vim.cmd.syntax("match markdownCode /`[^`]\\+`/ conceal")
			parser.init(event.buf)
			renderer.render(event.buf)
		end
	})

	vim.api.nvim_create_autocmd({"InsertLeave"}, {
		pattern = "*.md",
		callback = function (event)
			vim.cmd.syntax("match markdownCode /`[^`]\\+`/ conceal")
			vim.wo.conceallevel = 2
			vim.wo.concealcursor = "nc"

			parser.init(event.buf)
			renderer.render(event.buf)
		end
	})

	vim.api.nvim_create_autocmd({"InsertEnter"}, {
		pattern = "*.md",
		callback = function (event)
			vim.cmd("syntax clear markdownCode")
			vim.wo.conceallevel = 0
			vim.wo.concealcursor = "nc"

			renderer.clear(event.buf)
		end
	})
end

return M
