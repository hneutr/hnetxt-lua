local Path = require("hl.Path")

local db = require("htl.db")

local test_project = Path.tempdir:join("test-project")

before_each(function()
    test_project:rmdir()
    db.before_test()
end)

after_each(function()
    db.after_test()
end)
