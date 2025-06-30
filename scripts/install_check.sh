#!/bin/bash
# Simple installation verification script for zzvim-R

echo "zzvim-R Installation Check"
echo "=========================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_TOTAL=0

check() {
    local condition=$1
    local name="$2"
    local hint="$3"
    
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    
    if [ $condition -eq 1 ]; then
        echo -e "${GREEN}✓${NC} $name"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $name"
        if [ -n "$hint" ]; then
            echo "  Fix: $hint"
        fi
    fi
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check 1: Vim availability and version
if command -v vim >/dev/null 2>&1; then
    VIM_VERSION=$(vim --version | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    VIM_MAJOR=$(echo $VIM_VERSION | cut -d. -f1)
    VIM_MINOR=$(echo $VIM_VERSION | cut -d. -f2)
    
    if [ "$VIM_MAJOR" -gt 8 ] || ([ "$VIM_MAJOR" -eq 8 ] && [ "$VIM_MINOR" -ge 0 ]); then
        check 1 "Vim 8.0+ available" ""
        info "Vim version: $VIM_VERSION"
    else
        check 0 "Vim 8.0+ available" "Update Vim to version 8.0 or later"
    fi
else
    check 0 "Vim available" "Install Vim"
fi

# Check 2: Terminal support
if command -v vim >/dev/null 2>&1; then
    if vim --version | grep -q "+terminal"; then
        check 1 "Vim terminal support" ""
    else
        check 0 "Vim terminal support" "Install Vim with terminal support"
    fi
fi

# Check 3: R availability
if command -v R >/dev/null 2>&1; then
    check 1 "R executable available" ""
    R_VERSION=$(R --version | head -1)
    info "R version: $R_VERSION"
else
    check 0 "R executable available" "Install R and add to PATH"
fi

# Check 4: Plugin files exist
if [ -f "plugin/zzvim_r.vim" ]; then
    check 1 "Plugin core file exists" ""
else
    check 0 "Plugin core file exists" "Ensure plugin/zzvim_r.vim is present"
fi

if [ -f "autoload/zzvim_r.vim" ]; then
    check 1 "Plugin autoload file exists" ""
else
    check 0 "Plugin autoload file exists" "Ensure autoload/zzvim_r.vim is present"
fi

if [ -f "doc/zzvim-R.txt" ]; then
    check 1 "Help documentation exists" ""
else
    check 0 "Help documentation exists" "Ensure doc/zzvim-R.txt is present"
fi

# Check 5: Plugin loading test (basic syntax check)
echo
info "Testing plugin syntax..."

if command -v vim >/dev/null 2>&1; then
    # Just check if the plugin file has valid syntax
    if vim -u NONE -N -es -c "source plugin/zzvim_r.vim" -c "qa!" >/dev/null 2>&1; then
        check 1 "Plugin syntax valid" ""
    else
        check 0 "Plugin syntax valid" "Check for VimScript syntax errors in plugin/zzvim_r.vim"
    fi
    
    if vim -u NONE -N -es -c "source autoload/zzvim_r.vim" -c "qa!" >/dev/null 2>&1; then
        check 1 "Autoload syntax valid" ""
    else
        check 0 "Autoload syntax valid" "Check for VimScript syntax errors in autoload/zzvim_r.vim"
    fi
fi

# Results
echo
echo "Results: $CHECKS_PASSED/$CHECKS_TOTAL checks passed"
echo

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}🎉 Installation looks good!${NC}"
    echo
    echo "Quick start:"
    echo "1. vim test.R"
    echo "2. Press \\r to open R terminal"
    echo "3. Press <CR> to send lines to R"
    echo "4. :help zzvim-r for full documentation"
    echo
    echo "Run full verification: vim -S scripts/verify_installation.vim"
    exit 0
else
    echo -e "${RED}❌ Some issues found${NC}"
    echo
    echo "For detailed verification: vim -S scripts/verify_installation.vim"
    echo "For help: :help zzvim-r-troubleshooting"
    exit 1
fi