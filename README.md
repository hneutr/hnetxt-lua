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

TODO:
- `hnetxt-lua`:
  - `element`
    - `location.lua`:
      - `update`: figure out what to do; should this only be done from within vim?
      > - `move`: location should handle the `movement` stuff
  - `project`:
    ~ `config`: loads the project file + mirrors
    - `mirror.lua`
    - `journal.lua`
  - `goals.lua`

=-----------------------------------------------------------
= [migrating nvim/lua/lex/config into hnetxt-lua]()
=-----------------------------------------------------------
- references in:
  - `ftplugin/markdown.lua`
  - `lua/lex/journal.lua`
  - `lua/lex/mirror.lua`
  - `lua/lex/config.lua`
  - `lua/lex/link.lua`
  - `lua/lex/index.lua`
  - `lua/lex/move.lua`
  - `lua/lex/sync.lua` also depends on it
