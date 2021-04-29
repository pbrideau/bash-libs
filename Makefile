
PREFIX ?= ${HOME}/.local

all:
	@echo "Nothing to compile, run make install to install"

.PHONY: install
install:
	@echo "Installing…"
	install -m 644 -D common.sh $(PREFIX)/lib/bash-libs/common.sh
	install -m 644 -D bash-template-getopt $(PREFIX)/share/bash-libs/bash-template-getopt
	install -m 644 -D bash-template-docopt $(PREFIX)/share/bash-libs/bash-template-docopt
	install -m 755 -D genbash $(PREFIX)/bin/genbash
	install -m 755 -D colortest $(PREFIX)/bin/colortest

.PHONY: uninstall
uninstall:
	@echo "Uninstalling…"
	rm -rf $(PREFIX)/lib/bash-libs
	rm -rf $(PREFIX)/share/bash-libs
	rm $(PREFIX)/bin/genbash
	rm $(PREFIX)/bin/colortest

.PHONY: test
test: common.sh
	bats test/

.PHONY: reinstall
reinstall: uninstall install
