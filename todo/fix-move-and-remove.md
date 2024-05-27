We want move to be better, and to work in all cases.

- projects:
  ✓ `DB.projects:insert`: update urls
  ✓ `DB.projects:remove`: update urls/remove them if they have no project
  ✓ `htc.move(old project dir, new project dir)`: update `DB.projects.path`
  ✓ `htc.remove(dir containing project dir)`: call `DB.projects:remove`
- urls:
  ✓ `source` has url and `target` should have url: update `source.path`
  ✓ `source` has url and `target` SHOULD NOT have url: delete `source`
  ✓ `source` has no url and `target` should have url: insert `target`

- `DB.urls:remove`:
  ⨉ delete mirrors
  ✓ clean references

╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸

things to do:
1. implement `DB.urls.path_should_have_url`
