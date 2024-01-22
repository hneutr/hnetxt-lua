test:
	nvim --headless --noplugin -u test/minimal_init.vim -c "PlenaryBustedDirectory test/auto/ { minimal_init = './test/minimal_init.vim' }"
