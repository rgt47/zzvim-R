#!/bin/bash
# Test runner script for zzvim-R plugin

echo "zzvim-R Plugin Test Suite"
echo "========================="

# Function to run a single test
run_test() {
    local test_file="$1"
    local test_name="$2"
    
    echo ""
    echo "Running $test_name..."
    echo "$(printf '%*s' "${#test_name}" '' | tr ' ' '-')"
    
    if vim -u NONE -es -S "$test_file" < /dev/null; then
        echo "✓ $test_name PASSED"
        return 0
    else
        echo "✗ $test_name FAILED"
        return 1
    fi
}

# Initialize counters
total_tests=0
passed_tests=0

# Run plugin loading test
if run_test "tests/quick_test.vim" "Plugin Loading"; then
    ((passed_tests++))
fi
((total_tests++))

# Only run full tests if plugin loads successfully
if [[ $passed_tests -eq 1 ]]; then
    echo ""
    echo "Plugin loads successfully. Running full test suite..."
    
    # Unit tests don't require R
    if run_test "tests/unit/test_configuration.vim" "Configuration Tests"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    if run_test "tests/unit/test_functions.vim" "Function Tests"; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    # Integration tests require R
    if command -v R >/dev/null 2>&1; then
        echo ""
        echo "R found. Running integration tests..."
        if run_test "tests/integration/test_basic_functionality.vim" "Integration Tests"; then
            ((passed_tests++))
        fi
        ((total_tests++))
    else
        echo ""
        echo "⚠ Skipping integration tests (R not found in PATH)"
    fi
else
    echo ""
    echo "❌ Plugin failed to load. Skipping other tests."
fi

# Print results
echo ""
echo "Test Results:"
echo "============="
echo "Passed: $passed_tests/$total_tests"

if [[ $passed_tests -eq $total_tests ]]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "❌ Some tests failed."
    exit 1
fi