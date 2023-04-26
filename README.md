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

=-----------------------------------------------------------
= [movement stuff]()
=-----------------------------------------------------------
- implement Mark.find
- move to `hnetxt-lua`:
  - `hnetxt-nvim.text.divider`
  - `hnetxt-nvim.text.header`
  - `hnetxt-nvim.text.list`
  - `hnetxt-nvim.ui.fold`


- move `hnetxt-lua.element` to `hnetxt-lua.text`
