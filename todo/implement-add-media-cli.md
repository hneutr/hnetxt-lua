is a: todo

usage: `add-media`
- `-c/--collection`: reference to collection
  - if provided: default `type` to `file`
  - else: default `type` to `directory`
- `-t/--type`:
  - values:
    - file
    - directory
  - optional
- positional arg 1: title, invert `DB.urls:get_label()` process
