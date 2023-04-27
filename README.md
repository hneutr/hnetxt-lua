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
- todo: finish up `hnetxt-lua.project.move.operation`

----------------------------------------
TODO:
- Operation:
    - map_mirrors: test
    - process: test
    - update_references: implement
    - file_is_dir_file: test
    - dir_file: test
    - evaluate: test
    - applies: test
- FileToMarkOperation:
    - map_mirrors: test
    - process: test
    - update_references: implement
- DirOperation:
    - map_a_to_b: test (might already be done in `Inferrer`)
    - case:
        - to_files:
            - map_a_to_b: text
- MarkOperation:
    - process: test
