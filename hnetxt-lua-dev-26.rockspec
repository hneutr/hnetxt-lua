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
        ["hl"] = "lua/hl/init.lua",
        ["hl.io"] = "lua/hl/io.lua",
        ["hl.string"] = "lua/hl/string.lua",
        ["hl.yaml"] = "lua/hl/yaml.lua",

        ["hl.List"] = "lua/hl/List.lua",
        ["hl.Dict"] = "lua/hl/Dict.lua",
        ['hl.Set'] = "lua/hl/Set.lua",
        ["hl.Path"] = "lua/hl/Path.lua",
        ["hl.Tree"] = "lua/hl/Tree.lua",
        
        ["hl.DataFrame"] = "lua/hl/DataFrame.lua",

        ["htl"] = "lua/htl/init.lua",
        ["htl.config"] = "lua/htl/config.lua",

        ["htl.journal"] = "lua/htl/journal.lua",
        ["htl.track"] = "lua/htl/track.lua",
        ["htl.goals"] = "lua/htl/goals.lua",

        ["htl.snippet"] = "lua/htl/snippet.lua",
        ['htl.metadata'] = "lua/htl/metadata.lua",

        -- db
        ["htl.db"] = "lua/htl/db/init.lua",
        ["htl.db.projects"] = "lua/htl/db/projects.lua",
        ["htl.db.urls"] = "lua/htl/db/urls.lua",

        -- to revise
        ["htl.operator"] = "lua/htl/operator/init.lua",
        ["htl.operator.operation"] = "lua/htl/operator/operation/init.lua",
        ["htl.operator.operation.dir"] = "lua/htl/operator/operation/dir.lua",
        ["htl.operator.operation.file"] = "lua/htl/operator/operation/file.lua",

        ["htl.project.mirror"] = "lua/htl/project/mirror/init.lua",
        ["htl.project.mirror.config"] = "lua/htl/project/mirror/config.lua",

        ["htl.text.divider"] = "lua/htl/text/divider.lua",
        ["htl.text.header"] = "lua/htl/text/header.lua",
        ["htl.text.Parser"] = "lua/htl/text/Parser.lua",
        ["htl.text.Line"] = "lua/htl/text/Line.lua",
        ["htl.text.List"] = "lua/htl/text/List/init.lua",
        ["htl.text.List.Item"] = "lua/htl/text/List/Item.lua",
        ["htl.text.List.NumberedItem"] = "lua/htl/text/List/NumberedItem.lua",

        ["htl.text.link"] = "lua/htl/text/link.lua",
        ["htl.text.location"] = "lua/htl/text/location.lua",
        ["htl.text.mark"] = "lua/htl/text/mark.lua",
        ["htl.text.reference"] = "lua/htl/text/reference.lua",

        -- cli
        ["htc"] = "lua/htc/init.lua",
        ["htc.command"] = "lua/htc/command.lua",
        ["htc.colorize"] = "lua/htc/colorize.lua",

        ["htc.journal"] = "lua/htc/journal.lua",
        ["htc.track"] = "lua/htc/track.lua",
        ["htc.aim"] = "lua/htc/aim.lua",
        ["htc.new"] = "lua/htc/new.lua",
        ["htc.tags"] = "lua/htc/tags.lua",
        ["htc.project"] = "lua/htc/project.lua",

        ["htc.move"] = "lua/htc/move.lua",
        ["htc.remove"] = "lua/htc/remove.lua",

        -- to start using after `htc.operator.*` is gone
        ["htl.move"] = "lua/htl/move.lua",
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
