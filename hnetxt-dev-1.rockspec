package = "hnetxt"
version = "dev-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   homepage = "*** please enter a project homepage ***",
   license = "*** please specify a license ***"
}
dependencies = {
    "lyaml >= 6.2",
    "inspect >= 3.1",
    "lua-cjson >= 2.1",
    "luafilesystem >= 1.8",
}
build = {
   type = "builtin",
   modules = {
       setup = "src/setup.lua",

       project = "src/project/init.lua",

       const = "src/const.lua",

       util = "src/util/init.lua",
       ["util.path"] = "src/util/path.lua",
       ["util.table"] = "src/util/table.lua",
       ["util.string"] = "src/util/string.lua",
   }
}
