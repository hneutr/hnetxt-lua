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
        ["hl"] = "src/hl/init.lua",
        ["hl.io"] = "src/hl/io.lua",
        ["hl.object"] = "src/hl/object.lua",
        ["hl.string"] = "src/hl/string.lua",
        ["hl.yaml"] = "src/hl/yaml.lua",
        ["hl.List"] = "src/hl/List.lua",
        ["hl.Dict"] = "src/hl/Dict.lua",
        ['hl.Set'] = "src/hl/Set.lua",
        ["hl.Path"] = "src/hl/Path.lua",
        ["hl.DataFrame"] = "src/hl/DataFrame.lua",

        ["htl"] = "src/htl/init.lua",
        ["htl.config"] = "src/htl/config.lua",

        ["htl.journal"] = "src/htl/journal.lua",
        ["htl.track"] = "src/htl/track.lua",

        ["htl.snippet"] = "src/htl/snippet.lua",
        ['htl.metadata'] = "src/htl/metadata.lua",

        ["htl.operator"] = "src/htl/operator/init.lua",
        ["htl.operator.operation"] = "src/htl/operator/operation/init.lua",
        ["htl.operator.operation.dir"] = "src/htl/operator/operation/dir.lua",
        ["htl.operator.operation.file"] = "src/htl/operator/operation/file.lua",
        ["htl.operator.operation.mark"] = "src/htl/operator/operation/mark.lua",

        ["htl.parse"] = "src/htl/parse/init.lua",
        ["htl.parse.fold"] = "src/htl/parse/fold.lua",

        ["htl.project"] = "src/htl/project/init.lua",
        ["htl.project.registry"] = "src/htl/project/registry.lua",
        ["htl.project.mirror"] = "src/htl/project/mirror/init.lua",
        ["htl.project.mirror.config"] = "src/htl/project/mirror/config.lua",

        ["htl.text.divider"] = "src/htl/text/divider.lua",
        ["htl.text.header"] = "src/htl/text/header.lua",
        ["htl.text.link"] = "src/htl/text/link.lua",
        ["htl.text.list"] = "src/htl/text/list.lua",
        ["htl.text.location"] = "src/htl/text/location.lua",
        ["htl.text.mark"] = "src/htl/text/mark.lua",
        ["htl.text.reference"] = "src/htl/text/reference.lua",
        ["htl.text.Line"] = "src/htl/text/Line.lua",
        ["htl.text.NeoList"] = "src/htl/text/NeoList/init.lua",
        ["htl.text.NeoList.Item"] = "src/htl/text/NeoList/Item.lua",
        ["htl.text.NeoList.NumberedItem"] = "src/htl/text/NeoList/NumberedItem.lua",
        -- neo
        ["htl.text.neoparse"] = "src/htl/text/neoparse.lua",

        ["htl.notes"] = "src/htl/notes/init.lua",
        ["htl.notes.set"] = "src/htl/notes/set/init.lua",
        ["htl.notes.set.file"] = "src/htl/notes/set/file.lua",
        ["htl.notes.set.topic"] = "src/htl/notes/set/topic.lua",
        ["htl.notes.set.prompt"] = "src/htl/notes/set/prompt.lua",
        ["htl.notes.set.intention"] = "src/htl/notes/set/intention.lua",
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

        ["htl.goals.goal"] = "src/htl/goals/goal.lua",
        ["htl.goals.set"] = "src/htl/goals/set/init.lua",
        ["htl.goals.set.year"] = "src/htl/goals/set/year.lua",
        ["htl.goals.set.month"] = "src/htl/goals/set/month.lua",
        ["htl.goals.set.week"] = "src/htl/goals/set/week.lua",
        ["htl.goals.set.day"] = "src/htl/goals/set/day.lua",
        ["htl.goals.set.undated"] = "src/htl/goals/set/undated.lua",

        -- cli
        ["htc"] = "src/htc/init.lua",
        ["htc.command"] = "src/htc/command.lua",
        ["htc.util"] = "src/htc/util.lua",
        ["htc.colors"] = "src/htc/colors.lua",
        ["htc.colorize"] = "src/htc/colorize.lua",

        ["htc.journal"] = "src/htc/journal.lua",
        ["htc.new"] = "src/htc/new.lua",
        ["htc.tags"] = "src/htc/tags.lua",
        ["htc.track"] = "src/htc/track.lua",

        ["htc.project"] = "src/htc/project.lua",
        ["htc.move"] = "src/htc/move.lua",
        ["htc.remove"] = "src/htc/remove.lua",
        ["htc.goals"] = "src/htc/goals.lua",
        ["htc.aim"] = "src/htc/aim.lua",
        ["htc.notes"] = "src/htc/notes.lua",
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
