local stub = require('luassert.stub')

local Location = require("htn.text.location")
local Link = require("htl.text.link")

local Path = require("hn.path")


describe("goto", function() 
    local open_command = "edit"
    local current_file
    local open_path
    local buf

    before_each(function()
        vim.b.htn_project = {}

        current_file = Path.this
        Path.this = function() return "file" end

        stub(Path, "open")
        stub(Link, "find_label")
    end)

    after_each(function()
        vim.b.htn_project = {}

        Path.this = this

        Path.open:revert()
        Link.find_label:revert()
    end)

    it("str: -; Path.open: -; Link.find_label: +", function()
        local lines = {
            "a",
            "b",
            "[m1]()",
            "[r1](file:m3)",
            "",
            "[m2]()",
            "[r2](m2)",
        }

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_command("buffer " .. buf)
        vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)

        vim.api.nvim_win_set_cursor(0, {4, 0})

        Location.goto(open_command)

        assert.stub(Path.open).was_not_called()
        assert.stub(Link.find_label).was_called()
    end)

    it("str: +; project_root: +; Path.open: +; Link.find_label: -", function()
        vim.b.htn_project.path = "dir"
        Location.goto(open_command, "[a](f1)")

        assert.stub(Path.open).was_called()
        assert.stub(Link.find_label).was_not_called()
    end)
end)
