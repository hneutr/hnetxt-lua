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
        ['hl.Set'] = "src/hl/Set.lua",
        ["hl.Path"] = "src/hl/Path.lua",
        ["hl.Tree"] = "src/hl/Tree.lua",
        ["hl.UnitTest"] = "src/hl/UnitTest.lua",
        ["hl.SqliteTable"] = "src/hl/SqliteTable.lua",
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
        ["htl.db.Instances"] = "src/htl/db/Instances.lua",
        ["htl.db.Taxonomy"] = "src/htl/db/Taxonomy.lua",
        ["htl.db.Metadata"] = "src/htl/db/Metadata.lua",

        ["htl.Metadata.Condition"] = "src/htl/Metadata/Condition.lua",
        ["htl.Metadata.Conditions"] = "src/htl/Metadata/Conditions.lua",
        ["htl.Metadata.Taxonomy"] = "src/htl/Metadata/Taxonomy.lua",

        ["htl.Mirrors"] = "src/htl/Mirrors.lua",

        ["htl.text.Line"] = "src/htl/text/Line.lua",
        ["htl.text.List"] = "src/htl/text/List/init.lua",
        ["htl.text.List.Item"] = "src/htl/text/List/Item.lua",
        ["htl.text.List.NumberedItem"] = "src/htl/text/List/NumberedItem.lua",
        ["htl.text.Link"] = "src/htl/text/Link.lua",
        ["htl.text.TerminalLink"] = "src/htl/text/TerminalLink.lua",
        ["htl.text.Heading"] = "src/htl/text/Heading.lua",
        ["htl.text.Document"] = "src/htl/text/Document.lua",

        -- cli
        ["htc.hnetxt"] = "src/htc/hnetxt.lua",
        ["htc.project"] = "src/htc/project.lua",
        ["htc.remove"] = "src/htc/remove.lua",
        ["htc.move"] = "src/htc/move.lua",
        ["htc.Metadata"] = "src/htc/Metadata/init.lua",
        ["htc.Metadata.Ontology"] = "src/htc/Metadata/Ontology.lua",
        ["htc.Metadata.Predicates"] = "src/htc/Metadata/Predicates.lua",
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
