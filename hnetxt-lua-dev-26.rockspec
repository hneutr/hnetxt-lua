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
    "luv",
   "plenary.nvim",
   "lua >= 5.1",
   "lyaml >= 6.2",
   "inspect >= 3.1",
   "luajit >= 2.1",
   "lua-cjson >= 2.1",
}
build = {
   type = "builtin",
    modules = {
        ["hl"] = "src/hl/init.lua",
        ["hl.io"] = "src/hl/io.lua",
        ["hl.string"] = "src/hl/string.lua",
        ["hl.yaml"] = "src/hl/yaml.lua",

        ["hl.List"] = "src/hl/List.lua",
        ["hl.Dict"] = "src/hl/Dict.lua",
        ['hl.Set'] = "src/hl/Set.lua",
        ["hl.Path"] = "src/hl/Path.lua",
        ["hl.Tree"] = "src/hl/Tree.lua",
        
        ["hl.DataFrame"] = "src/hl/DataFrame.lua",

        ["htl"] = "src/htl/init.lua",
        ["htl.config"] = "src/htl/config.lua",

        ["htl.journal"] = "src/htl/journal.lua",
        ["htl.track"] = "src/htl/track.lua",
        ["htl.goals"] = "src/htl/goals.lua",

        ["htl.snippet"] = "src/htl/snippet.lua",
        ['htl.metadata'] = "src/htl/metadata.lua",

        -- db
        ["htl.db"] = "src/htl/db/init.lua",
        ["htl.db.projects"] = "src/htl/db/projects.lua",
        ["htl.db.urls"] = "src/htl/db/urls.lua",
        ["htl.db.mirrors"] = "src/htl/db/mirrors.lua",

        -- to revise
        ["htl.operator"] = "src/htl/operator/init.lua",
        ["htl.operator.operation"] = "src/htl/operator/operation/init.lua",
        ["htl.operator.operation.dir"] = "src/htl/operator/operation/dir.lua",
        ["htl.operator.operation.file"] = "src/htl/operator/operation/file.lua",

        ["htl.mirror"] = "src/htl/mirror.lua",

        ["htl.text.divider"] = "src/htl/text/divider.lua",
        ["htl.text.header"] = "src/htl/text/header.lua",
        ["htl.text.Parser"] = "src/htl/text/Parser.lua",
        ["htl.text.Line"] = "src/htl/text/Line.lua",
        ["htl.text.List"] = "src/htl/text/List/init.lua",
        ["htl.text.List.Item"] = "src/htl/text/List/Item.lua",
        ["htl.text.List.NumberedItem"] = "src/htl/text/List/NumberedItem.lua",

        ["htl.text.link"] = "src/htl/text/link.lua",
        ["htl.text.location"] = "src/htl/text/location.lua",
        ["htl.text.mark"] = "src/htl/text/mark.lua",
        ["htl.text.reference"] = "src/htl/text/reference.lua",

        -- cli
        ["htc"] = "src/htc/init.lua",
        ["htc.command"] = "src/htc/command.lua",
        ["htc.colorize"] = "src/htc/colorize.lua",

        ["htc.journal"] = "src/htc/journal.lua",
        ["htc.track"] = "src/htc/track.lua",
        ["htc.aim"] = "src/htc/aim.lua",
        ["htc.new"] = "src/htc/new.lua",
        ["htc.tags"] = "src/htc/tags.lua",
        ["htc.project"] = "src/htc/project.lua",

        ["htc.move"] = "src/htc/move.lua",
        ["htc.remove"] = "src/htc/remove.lua",

        -- to start using after `htc.operator.*` is gone
        ["htl.move"] = "src/htl/move.lua",
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
