ways they're bad:
- fold levels don't update well
  - I have to manually update them, and then I lose my manual folds
- when on a header, `zc`/`zo` should operate on the fold _below_ the header
- things should play nicely with fold movements:
  - `[z`/`]z`/`zj`/`zk`

things to do:
- use foldcolumn to show/hide folds
- set foldtext to nil to use standard highlighting

╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸

What I want folding to do:
1. while on a size S barrier, zo/zc opens/closes a fold that goes until the next size S barrier
