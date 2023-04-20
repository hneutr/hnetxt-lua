This is intended to be the single location for code that deals with writing.

#-------------------------------------------------------------------------------
# [architecture]()
#-------------------------------------------------------------------------------
- `lua/hnetxt`
  - `element`
    - `link.lua`
    - `location.lua`
      > - `move`: location should handle the `movement` stuff
    - `mark.lua`
    - `reference.lua`
    - `flag.lua`
  - `project`
    - `init.lua`
    ~ `config`: loads the project file + mirrors
    - `mirror.lua`
    - `journal.lua`
  - `goals.lua`
  - `config.lua`: easy way to load hnetxt constants
