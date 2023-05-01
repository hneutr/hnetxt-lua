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
    - `operator.lua`
    - `operation`:
        - `file.lua`
        - `dir.lua`
        - `mark.lua`
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
