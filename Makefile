THEMIS_REPO := https://github.com/thinca/vim-themis.git
THEMIS_DIR  := test/.deps/vim-themis
THEMIS_BIN  := $(THEMIS_DIR)/bin/themis

.PHONY: test smoke functional themis-install clean

test: smoke functional

smoke:
	vim -es -c 'source test/ci_smoke.vim'

functional: $(THEMIS_BIN)
	THEMIS_HOME=$(CURDIR)/$(THEMIS_DIR) $(CURDIR)/$(THEMIS_BIN) test/functional/

themis-install: $(THEMIS_BIN)

$(THEMIS_BIN):
	mkdir -p test/.deps
	git clone --depth 1 $(THEMIS_REPO) $(THEMIS_DIR)

clean:
	rm -rf test/.deps
