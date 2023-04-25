This is intended to be the single location for code that deals with writing.

#-------------------------------------------------------------------------------
# [architecture]()
#-------------------------------------------------------------------------------
- `hnetxt-lua`:
  - `project`:
    - `Project`
    - `registry.lua`: records paths
  - `element`:
    - `link.lua`
    - `location.lua`
    - `mark.lua`
    - `reference.lua`
    - `flag.lua`
  - `config.lua`: easy way to load hnetxt constants
  - `goals.lua`

TODO:
- `hnetxt-lua`:
  - `element`
      > - `move`: location should handle the `movement` stuff
  - `project`:
    ~ `config`: loads the project file + mirrors
    - `mirror.lua`

=-----------------------------------------------------------
= [migrating nvim/lua/lex/config into hnetxt-lua]()
=-----------------------------------------------------------
- references in:
  - `ftplugin/markdown.lua`
  - `lua/lex/mirror.lua`
  - `lua/lex/config.lua`
  - `lua/lex/index.lua`
  - `lua/lex/move.lua`
  - `lua/lex/sync.lua` also depends on it
