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
    "lua >= 5.1",
    "lyaml >= 6.2",
    "inspect >= 3.1",
    "lua-cjson >= 2.1",
    "argparse",
    "inspect",
    "lua-path",
    "luasocket",
    "fzf-lua",
    "htmlparser",
    "luasec",
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
        ["hl.DefaultDict"] = "src/hl/DefaultDict.lua",
        ['hl.Set'] = "src/hl/Set.lua",
        ["hl.Path"] = "src/hl/Path.lua",
        ["hl.Tree"] = "src/hl/Tree.lua",
        ["hl.utils"] = "src/hl/utils.lua",
        
        ["htl"] = "src/htl/init.lua",
        ["htl.Config"] = "src/htl/config.lua",
        ["htl.journal"] = "src/htl/journal.lua",
        ["htl.goals"] = "src/htl/goals.lua",
        ["htl.Snippet"] = "src/htl/snippet.lua",
        ["htl.ety"] = "src/htl/ety.lua",
        ["htl.Color"] = "src/htl/Color.lua",
        ["htl.cli"] = "src/htl/cli.lua",

        ["htl.db"] = "src/htl/db/init.lua",
        ["htl.db.util"] = "src/htl/db/util.lua",
        ["htl.db.projects"] = "src/htl/db/projects.lua",
        ["htl.db.urls"] = "src/htl/db/urls.lua",
        ["htl.db.samples"] = "src/htl/db/samples.lua",
        ["htl.db.Log"] = "src/htl/db/Log.lua",
        ["htl.db.Paths"] = "src/htl/db/Paths.lua",
        ["htl.db.Relations"] = "src/htl/db/Relations.lua",
        ["htl.db.Instances"] = "src/htl/db/Instances.lua",

        ["htl.Taxonomy"] = "src/htl/Taxonomy/init.lua",
        ["htl.Taxonomy.Parser"] = "src/htl/Taxonomy/Parser.lua",

        ["htl.Mirrors"] = "src/htl/Mirrors.lua",

        ["htl.text.Line"] = "src/htl/text/Line.lua",
        ["htl.text.List"] = "src/htl/text/List/init.lua",
        ["htl.text.List.Item"] = "src/htl/text/List/Item.lua",
        ["htl.text.List.NumberedItem"] = "src/htl/text/List/NumberedItem.lua",
        ["htl.text.Link"] = "src/htl/text/Link.lua",
        ["htl.text.URLDefinition"] = "src/htl/text/URLDefinition.lua",
        ["htl.text.TerminalLink"] = "src/htl/text/TerminalLink.lua",

        -- cli
        ["htc.hnetxt"] = "src/htc/hnetxt.lua",
        ["htc.project"] = "src/htc/project.lua",
        ["htc.remove"] = "src/htc/remove.lua",
        ["htc.move"] = "src/htc/move.lua",
        ["htc.Ontology"] = "src/htc/Ontology.lua",
        ["htc.ety"] = "src/htc/ety.lua",
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
