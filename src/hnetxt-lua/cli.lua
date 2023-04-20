local Project = require("hnetxt-lua.project")

M = {}
function M.run(args)
    print(require("inspect")(args))
    print(require("inspect")(args[1]))
    print(require("inspect")(#args))
end

M.run(arg)
