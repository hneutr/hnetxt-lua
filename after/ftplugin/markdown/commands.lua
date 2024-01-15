local cmd = vim.api.nvim_buf_create_user_command

local Path = require("hn.path")
local Journal = require("htl.journal")
local Goals = require("htl.goals.set")
local Track = require("htl.track")

cmd(0, "Journal", function() Path.open(Journal()) end, {})
cmd(0, "Aim", function() Path.open(Goals.touch()) end, {})
cmd(0, "Track", function() Path.open(Track():touch()) end, {})
