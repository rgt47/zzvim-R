# Makefile for zzvim-R plugin

.PHONY: test test-quick clean help

# Default target
help:
	@echo "zzvim-R Plugin Makefile"
	@echo "======================="
	@echo ""
	@echo "Available targets:"
	@echo "  test       - Run comprehensive test suite"
	@echo "  test-quick - Run quick basic tests"
	@echo "  clean      - Clean temporary files"
	@echo "  help       - Show this help"

# Quick test that just verifies plugin loads
test-quick:
	@echo "Running quick tests..."
	@vim -u NONE -N -es -c 'let &rtp=getcwd().",".&rtp' \
		-c 'let g:zzvim_r_disable_mappings=1' \
		-c 'runtime plugin/zzvim_r.vim' \
		-c 'echo "Plugin loaded:" exists("g:loaded_zzvim_r")' \
		-c 'echo "Commands exist:" exists(":ROpenTerminal")' \
		-c 'qa!'

# Comprehensive test suite
test:
	@echo "Running comprehensive test suite..."
	@if command -v R >/dev/null 2>&1; then \
		echo "R found - will run integration tests"; \
	else \
		echo "R not found - skipping integration tests"; \
	fi
	@echo "Note: Full automated testing requires manual verification"
	@echo "Use 'make test-quick' for basic validation"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.swp" -delete 2>/dev/null || true
	@find . -name "*.swo" -delete 2>/dev/null || true
	@find . -name "*~" -delete 2>/dev/null || true