THEMIS_REPO := https://github.com/thinca/vim-themis.git
THEMIS_DIR  := test/.deps/vim-themis
THEMIS_BIN  := $(THEMIS_DIR)/bin/themis

# Editor to use for smoke tests. Override for Neovim:
#   make smoke SMOKE_CMD='nvim --headless'
SMOKE_CMD ?= vim -es

# Editor themis should invoke. Defaults to vim; override with nvim:
#   make functional THEMIS_VIM=nvim
THEMIS_VIM ?= vim

.PHONY: test smoke functional themis-install clean

test: smoke functional

smoke:
	$(SMOKE_CMD) -c 'source test/ci_smoke.vim' </dev/null

functional: $(THEMIS_BIN)
	THEMIS_HOME=$(CURDIR)/$(THEMIS_DIR) THEMIS_VIM=$(THEMIS_VIM) \
		$(CURDIR)/$(THEMIS_BIN) test/functional/

themis-install: $(THEMIS_BIN)

$(THEMIS_BIN):
	mkdir -p test/.deps
	git clone --depth 1 $(THEMIS_REPO) $(THEMIS_DIR)

clean:
	rm -rf test/.deps
