globals = {
    "Conf",
    "DB",
    "Dict",
    "List",
    "class",
    "Path",
    "SqliteTable",
    "Set",
    "utils",
    "DefaultDict",
    "Tree",
    "vim",
    "TIME",
}
ignore = {
    "214", -- allow access to _vars
    "512", -- allow single-iteration loops
    "142", -- allow setting undefined keys of a global var
    "143", -- allow accessing undefined keys of a global var
}

self = false
