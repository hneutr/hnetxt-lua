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
    "lua-cjson >= 2.1",
    "argparse",
    "lua-path",
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
        ["hl.utils"] = "src/hl/utils.lua",
        
        ["htl"] = "src/htl/init.lua",
        ["htl.Config"] = "src/htl/config.lua",
        ["htl.journal"] = "src/htl/journal.lua",
        ["htl.track"] = "src/htl/track.lua",
        ["htl.goals"] = "src/htl/goals.lua",
        ["htl.snippet"] = "src/htl/snippet.lua",
        ['htl.taxonomy'] = "src/htl/taxonomy.lua",

        ["htl.db"] = "src/htl/db/init.lua",
        ["htl.db.projects"] = "src/htl/db/projects.lua",
        ["htl.db.urls"] = "src/htl/db/urls.lua",
        ["htl.db.mirrors"] = "src/htl/db/mirrors.lua",
        ["htl.db.metadata"] = "src/htl/db/metadata.lua",

        ["htl.text.divider"] = "src/htl/text/divider.lua",
        ["htl.text.header"] = "src/htl/text/header.lua",
        ["htl.text.Parser"] = "src/htl/text/Parser.lua",
        ["htl.text.Line"] = "src/htl/text/Line.lua",
        ["htl.text.List"] = "src/htl/text/List/init.lua",
        ["htl.text.List.Item"] = "src/htl/text/List/Item.lua",
        ["htl.text.List.NumberedItem"] = "src/htl/text/List/NumberedItem.lua",
        ["htl.text.Link"] = "src/htl/text/Link.lua",
        ["htl.text.URLDefinition"] = "src/htl/text/URLDefinition.lua",

        -- cli
        ["htc"] = "src/htc/init.lua",
        ["htc.cli"] = "src/htc/cli.lua",
        ["htc.colorize"] = "src/htc/colorize.lua",
        ["htc.new"] = "src/htc/new.lua",
        ["htc.project"] = "src/htc/project.lua",
        ["htc.remove"] = "src/htc/remove.lua",
        ["htc.move"] = "src/htc/move.lua",
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
