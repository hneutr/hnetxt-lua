This is intended to be the single location for code that deals with writing.

#-------------------------------------------------------------------------------
# [architecture]()
#-------------------------------------------------------------------------------
- `hnetxt-lua`:
  - `project`:
    - `Project`
    - `registry.lua`: records paths
    - `mirror`:
      - `init.lua`
      - `config.lua`
  - `text`:
    - `link.lua`
    - `location.lua`
    - `mark.lua`
    - `reference.lua`
    - `flag.lua`
  - `config.lua`: easy way to load hnetxt constants
  - `goals.lua`

=-----------------------------------------------------------
= [movement stuff]()
=-----------------------------------------------------------
- TODO: have `Operation:operate` handle relative paths
- probably remove `hnetxt-lua.text.Reference.get_reference_locations` which is only used by `lex.move`
- probably remove `hnetxt-lua.text.Location.update`
- test actions:
  - file:map_mirrors
  - file:to mark:process
  - dir:map_mirrors
  - mark:process
