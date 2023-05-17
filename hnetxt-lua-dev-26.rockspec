rockspec_format = "3.0"
package = "hnetxt-lua"
version = "dev-26"
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
   "lua-cjson >= 2.1"
}
build = {
   type = "builtin",
   modules = {
      htl = "src/htl/init.lua",
      ["htl.config"] = "src/htl/config.lua",
      ["htl.goals"] = "src/htl/goals.lua",
      ["htl.journal"] = "src/htl/journal.lua",
      ["htl.operator"] = "src/htl/operator/init.lua",
      ["htl.operator.operation"] = "src/htl/operator/operation/init.lua",
      ["htl.operator.operation.dir"] = "src/htl/operator/operation/dir.lua",
      ["htl.operator.operation.file"] = "src/htl/operator/operation/file.lua",
      ["htl.operator.operation.mark"] = "src/htl/operator/operation/mark.lua",
      ["htl.parse"] = "src/htl/parse/init.lua",
      ["htl.parse.fold"] = "src/htl/parse/fold.lua",
      ["htl.project"] = "src/htl/project/init.lua",
      ["htl.project.mirror"] = "src/htl/project/mirror/init.lua",
      ["htl.project.mirror.config"] = "src/htl/project/mirror/config.lua",
      ["htl.project.registry"] = "src/htl/project/registry.lua",
      ["htl.text.divider"] = "src/htl/text/divider.lua",
      ["htl.text.flag"] = "src/htl/text/flag.lua",
      ["htl.text.header"] = "src/htl/text/header.lua",
      ["htl.text.link"] = "src/htl/text/link.lua",
      ["htl.text.list"] = "src/htl/text/list.lua",
      ["htl.text.location"] = "src/htl/text/location.lua",
      ["htl.text.mark"] = "src/htl/text/mark.lua",
      ["htl.text.reference"] = "src/htl/text/reference.lua"

      ["htl.project.notes"] = "src/htl/project/notes/init.lua",
      ["htl.project.notes.entries"] = "src/htl/project/notes/entries.lua",
      ["htl.project.notes.entry"] = "src/htl/project/notes/entry/init.lua",
      ["htl.project.notes.entry.prompt"] = "src/htl/project/notes/entry/prompt.lua",
      ["htl.project.notes.entry.response"] = "src/htl/project/notes/entry/response.lua",
      ["htl.project.notes.field"] = "src/htl/project/notes/field/init.lua",
      ["htl.project.notes.field.bool"] = "src/htl/project/notes/field/bool.lua",
      ["htl.project.notes.field.date"] = "src/htl/project/notes/field/date.lua",
      ["htl.project.notes.field.list"] = "src/htl/project/notes/field/list.lua",
      ["htl.project.notes.fields"] = "src/htl/project/notes/fields.lua",
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
