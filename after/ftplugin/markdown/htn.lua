local Path = require("hn.path")

local cmd = vim.api.nvim_buf_create_user_command

cmd(0, "Journal", function() Path.open(require("htl.journal")()) end, {})
cmd(0, "Aim", function() Path.open(require("htl.goals")()) end, {})
cmd(0, "Track", function() Path.open(require("htl.track")():touch()) end, {})
