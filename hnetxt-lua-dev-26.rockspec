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
      ["htl.text.reference"] = "src/htl/text/reference.lua",

      ["htl.notes"] = "src/htl/notes/init.lua",
      ["htl.notes.set"] = "src/htl/notes/set/init.lua",
      ["htl.notes.set.file"] = "src/htl/notes/set/file.lua",
      ["htl.notes.set.topic"] = "src/htl/notes/set/topic.lua",
      ["htl.notes.set.prompt"] = "src/htl/notes/set/prompt.lua",
      ["htl.notes.set.dated"] = "src/htl/notes/set/dated.lua",

      ["htl.notes.field"] = "src/htl/notes/field/init.lua",
      ["htl.notes.field.string"] = "src/htl/notes/field/string.lua",
      ["htl.notes.field.bool"] = "src/htl/notes/field/bool.lua",
      ["htl.notes.field.date"] = "src/htl/notes/field/date.lua",
      ["htl.notes.field.list"] = "src/htl/notes/field/list.lua",
      ["htl.notes.field.start"] = "src/htl/notes/field/start.lua",
      ["htl.notes.field.end"] = "src/htl/notes/field/end.lua",

      ["htl.notes.note.file"] = "src/htl/notes/note/file.lua",
      ["htl.notes.note.statement"] = "src/htl/notes/note/statement.lua",
      ["htl.notes.note.blank"] = "src/htl/notes/note/blank.lua",
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
