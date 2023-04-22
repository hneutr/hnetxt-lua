This is intended to be the single location for code that deals with writing.

#-------------------------------------------------------------------------------
# [architecture]()
#-------------------------------------------------------------------------------
- `hnetxt-lua`:
  - `project`:
    - `Project`
    - `registry.lua`: records paths
  - `config.lua`: easy way to load hnetxt constants

TODO:
- `hnetxt-lua`:
  - `element`
    - `link.lua`
    - `location.lua`
      > - `move`: location should handle the `movement` stuff
    - `mark.lua`
    - `reference.lua`
    - `flag.lua`
    - `init.lua`
  - `project`:
    ~ `config`: loads the project file + mirrors
    - `mirror.lua`
    - `journal.lua`
  - `goals.lua`

#-------------------------------------------------------------------------------
# [differences from lex]()
#-------------------------------------------------------------------------------
- `Link.get_nearest`: takes a str and position (instead of getting them from the nvim buffer)
- `Link.from_str`: takes a str (instead of getting it from the nvim buffer)
