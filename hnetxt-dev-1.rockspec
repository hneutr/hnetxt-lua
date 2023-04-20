rockspec_format = "3.0"
package = "hnetxt"
version = "dev-1"
source = {
   url = "https://github.com/hneutr/hnetxt-lua"
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
    "luafilesystem >= 1.8",
    "hneutil-lua",
}
build = {
   type = "builtin",
   modules = {
       setup = "src/setup.lua",

       hnetxt = "src/hnetxt/init.lua",

       ["hnetxt.project"] = "src/hnetxt/project/init.lua",
       ["hnetxt.const"] = "src/hnetxt/const.lua",
       ["hnetxt.config"] = "src/hnetxt/config.lua",
       ["hnetxt.cli"] = "src/hnetxt/cli.lua",
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
