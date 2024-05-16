cases:
- open vim with:
  - one:
    - file:
      - new
      - existing
    - terminal:
  - multiple:
    - files
      - new
      - existing
    - termins
- with file in window:
  - open new window:
    - file
    - terminal
  - change window (tab/pane):
    - file
    - terminal
  - change window contents:
    - file
    - terminal

enter test case variables:
- #buffers:
  - single
  - multiple
- entrance type:
  - new vim
  - new window
  - new buffer object (same window)
- buffer object:
  - file
  - terminal

nvim_create_buf
nvim_open_win
nvim_open_term

nvim_buf_delete
nvim_win_close

nvim_set_current_buf
nvim_set_current_win

nvim_get_current_win
nvim_get_current_buf

nvim_list_wins
nvim_list_bufs

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
┣ exit test cases
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
- #buffers:
  - single
  - multiple
- exit type:
  - vim quit
  - buffer kill
  - window kill
  - window leave
  - buffer object change (same window)

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
┣ enter test cases
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸
- open vim with:
  - 1 file
  - 1 terminal
  - 2 files
  - 2 terminals
  - 1 file 1 terminal

