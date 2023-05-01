rockspec_format = "3.0"
package = "hnetxt-lua"
version = "dev-17"
source = {
   url = "git://github.com/hneutr/hnetxt-lua"
}
description = {
   homepage = "https://github.com/hneutr/hnetxt-lua",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "lyaml >= 6.2",
   "inspect >= 3.1",
   "lua-cjson >= 2.1",
   "hneutil-lua"
}
build = {
   type = "builtin",
   modules = {
      ["hnetxt-lua"] = "src/hnetxt-lua/init.lua",
      ["hnetxt-lua.config"] = "src/hnetxt-lua/config.lua",
      ["hnetxt-lua.goals"] = "src/hnetxt-lua/goals.lua",
      ["hnetxt-lua.parse.fold"] = "src/hnetxt-lua/parse/fold.lua",
      ["hnetxt-lua.parse"] = "src/hnetxt-lua/parse/init.lua",
      ["hnetxt-lua.project"] = "src/hnetxt-lua/project/init.lua",
      ["hnetxt-lua.project.mirror"] = "src/hnetxt-lua/project/mirror/init.lua",
      ["hnetxt-lua.project.mirror.config"] = "src/hnetxt-lua/project/mirror/config.lua",
      ["hnetxt-lua.project.registry"] = "src/hnetxt-lua/project/registry.lua",
      ["hnetxt-lua.text.divider"] = "src/hnetxt-lua/text/divider.lua",
      ["hnetxt-lua.text.flag"] = "src/hnetxt-lua/text/flag.lua",
      ["hnetxt-lua.text.header"] = "src/hnetxt-lua/text/header.lua",
      ["hnetxt-lua.text.link"] = "src/hnetxt-lua/text/link.lua",
      ["hnetxt-lua.text.list"] = "src/hnetxt-lua/text/list.lua",
      ["hnetxt-lua.text.location"] = "src/hnetxt-lua/text/location.lua",
      ["hnetxt-lua.text.mark"] = "src/hnetxt-lua/text/mark.lua",
      ["hnetxt-lua.text.reference"] = "src/hnetxt-lua/text/reference.lua",
      ["hnetxt-lua.project.move.operation"] = "src/hnetxt-lua/project/move/operation/init.lua",
      ["hnetxt-lua.project.move.operation.file"] = "src/hnetxt-lua/project/move/operation/file.lua",
      ["hnetxt-lua.project.move.operation.dir"] = "src/hnetxt-lua/project/move/operation/dir.lua",
      ["hnetxt-lua.project.move.operation.mark"] = "src/hnetxt-lua/project/move/operation/mark.lua",
      ["hnetxt-lua.project.move.operator"] = "src/hnetxt-lua/project/move/operator.lua",
      setup = "src/setup.lua"
   }
}
test = {
   type = "busted",
   platforms = {
      unix = {
         flags = {
            "--exclude-tags=ssh,git"
         }
      },
      windows = {
         flags = {
            "--exclude-tags=ssh,git,unix"
         }
      }
   }
}