This is intended to be the single location for code that deals with writing.

=-----------------------------------------------------------
= [architecture]()
=-----------------------------------------------------------
- `constants`: loads constants from `/dotfiles/lex/constants/*`
- `project`:
  - `config`: loads the project file + mirrors

=-----------------------------------------------------------
= [cli]()
=-----------------------------------------------------------
- commands should:
  - by default: return the result 
  - support a `print` parameter to print the result
- project commands should:
  - accept a project name
  - infer the project name if in a project directory
- `project`:
  - `start`:
    - [type](project type)
  - `root`: return project's root
    - [print]()
  - `journal`: return a project's journal or the default journal (create if it doesn't exist)
    - [print]()
- `goals`: return the path to the current goals file (create if it doesn't exist)
  - [print]()


=-----------------------------------------------------------
= [existing]()
=-----------------------------------------------------------
`nvim/lua/lex`:
- `config`: loads the project file + mirrors
⨉ `constants`: loads constants from `/dotfiles/lex/constants/*`
✓ `opener`: 
✓ `statusline`: 
- `index`: 
⨉ `goals`
⨉ `journal`:

- `mirror`:
- `scratch`
- `link`: 
- `move`
- `sync`

`hnetext.py` stuff:
- cli:
  - `project`:
    - `start`: begin a project
    ⨉ `print_root`: print the root directory of a given project
    - `set_metadata`: set a project's metadata field to a value
    - `set_status`: set a project's status
    - `show_by_status`: show projects by their status
    - `flags`: list items with a particular flag
  - `words`:
    - `unknown`: print an unknown word
  - `catalyze`: print catalysts
  - `session`:
    - `start`: print the session startup content
