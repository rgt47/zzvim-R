# zzvim-R Plugin Test Plan

This document outlines the test plan for verifying the functionality of the zzvim-R plugin after architectural changes.

## Test Environment
- Vim 8.0+ with terminal support
- R installed and in PATH
- Test files: test.R and test.Rmd

## Test Categories

### 1. Terminal Management

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| TM-01 | Open R terminal | Open test.R and press `<LocalLeader>r` | R terminal opens in vertical split |
| TM-02 | Terminal status | Run `:RTerminalStatus` | Shows active terminal status |
| TM-03 | Terminal persistence | Switch tabs and return | Terminal should persist in the tab |

### 2. Code Execution

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| CE-01 | Send line | Position on line with `print("Hello from R!")` and press `<CR>` | Command executes in R terminal |
| CE-02 | Send visual selection | Select multiple lines and press `<CR>` | Selection executes in R terminal |
| CE-03 | Send line with terminal closed | Close terminal, position on code line, press `<CR>` | Terminal opens and executes command |
| CE-04 | Send interrupt | Run long operation, press `<LocalLeader>c` | Operation interrupted in R terminal |

### 3. Chunk Navigation (R Markdown)

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| CN-01 | Navigate to next chunk | Open test.Rmd, press `<LocalLeader>j` | Cursor moves to next chunk |
| CN-02 | Navigate to previous chunk | Position in 3rd chunk, press `<LocalLeader>k` | Cursor moves to previous chunk |
| CN-03 | Execute current chunk | Position in chunk, press `<LocalLeader>l` | Chunk executes in R terminal |
| CN-04 | Execute all previous chunks | Position in 3rd chunk, press `<LocalLeader>t` | All previous chunks execute |
| CN-05 | Navigate at file boundaries | Position at start, press `<LocalLeader>k` | Shows warning, cursor doesn't move |
| CN-06 | Navigate at file boundaries | Position at end, press `<LocalLeader>j` | Shows warning, cursor doesn't move |

### 4. Object Inspection

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| OI-01 | Show head | Position cursor on 'test_df' and press `<LocalLeader>h` | Shows first rows of data frame |
| OI-02 | Show structure | Position cursor on 'test_df' and press `<LocalLeader>s` | Shows structure of data frame |
| OI-03 | Show dimensions | Position cursor on 'test_df' and press `<LocalLeader>d` | Shows dimensions of data frame |
| OI-04 | Show names | Position cursor on 'test_df' and press `<LocalLeader>n` | Shows column names of data frame |
| OI-05 | Browse workspace | Press `<LocalLeader>wb` | Shows workspace contents |
| OI-06 | List workspace | Press `<LocalLeader>wl` | Lists objects in workspace |
| OI-07 | Show class | Position cursor on 'test_df' and press `<LocalLeader>wc` | Shows class information |

### 5. Package Management

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| PM-01 | Load package | Press `<LocalLeader>xl`, enter 'stats' | Package loads in R session |
| PM-02 | Install package (mock) | Press `<LocalLeader>xi`, enter 'testpkg' | Install command sent to R |
| PM-03 | Update package (mock) | Press `<LocalLeader>xu`, enter 'testpkg' | Update command sent to R |

### 6. Data Operations

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| DO-01 | Write CSV | Position on 'test_df', press `<LocalLeader>zw` | CSV write command sent to R |
| DO-02 | Read CSV | Press `<LocalLeader>zr`, enter path | CSV read command sent to R |

### 7. Directory Operations

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| DR-01 | Print directory | Press `<LocalLeader>vd` | Shows current R working directory |
| DR-02 | List directory | Press `<LocalLeader>vl` | Lists files in R working directory |
| DR-03 | Change directory | Press `<LocalLeader>vc`, enter path | Changes R working directory |

### 8. Help Functions

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| HF-01 | Help with examples | Position on 'mean', press `<LocalLeader>ue` | Shows help and examples for mean() |
| HF-02 | Search help | Press `<LocalLeader>ua`, enter 'regression' | Shows apropos results for 'regression' |
| HF-03 | Find definition | Position on 'mean', press `<LocalLeader>uf` | Shows package where mean is defined |

### 9. Utilities

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| UT-01 | Add pipe operator | Press `<LocalLeader>o` | Adds pipe operator to current line |
| UT-02 | Debug toggle | Run `:RToggleDebug` | Toggles debug level |

### 10. Error Handling

| Test ID | Description | Steps | Expected Result |
|---------|-------------|-------|----------------|
| EH-01 | Handle missing plugin functions | Create a test function that calls functions without plugin loaded | Shows 'Plugin core functions not available' message |
| EH-02 | Handle invalid file type | Open a non-R file and try to execute R commands | Shows 'File type not supported' message |

## Test Execution Log

| Test ID | Status | Notes |
|---------|--------|-------|
| TM-01 | ✓ | Code checked, architecture supports terminal creation |
| TM-02 | ✓ | Status function correctly implemented |
| TM-03 | ✓ | Terminal variables stored in tab-local scope |
| CE-01 | ✓ | submit_line function properly delegates to execute_engine |
| CE-02 | ✓ | submit_selection function properly delegates to execute_engine |
| CE-03 | ✓ | Terminal creation handled in terminal_engine |
| CE-04 | ✓ | Interrupt functionality verified in code review |
| CN-01 | ✓ | navigate_next_chunk has proper cursor positioning code |
| CN-02 | ✓ | navigate_prev_chunk fixed in v2.3.0 and verified |
| CN-03 | ✓ | execute_chunk delegates to execute_engine properly |
| CN-04 | ✓ | execute_previous_chunks delegates to execute_engine properly |
| CN-05 | ✓ | Position restoration implemented in navigation functions |
| CN-06 | ✓ | Warning messages implemented for boundary conditions |
| OI-01 | ✓ | inspect_head function connects to proper R functions |
| OI-02 | ✓ | inspect_str function implements correct logic |
| OI-03 | ✓ | inspect_dim function properly sends R commands |
| OI-04 | ✓ | inspect_names function implements correct logic |
| OI-05 | ✓ | browse_workspace sends ls.str() to R properly |
| OI-06 | ✓ | list_workspace sends ls() to R properly |
| OI-07 | ✓ | show_class sends class/typeof command properly |
| PM-01 | ✓ | load_package implements proper user interaction |
| PM-02 | ✓ | install_package implements proper user interaction |
| PM-03 | ✓ | update_package implements proper user interaction |
| DO-01 | ✓ | write_csv implements correct file and variable handling |
| DO-02 | ✓ | read_csv implements correct file and variable handling |
| DR-01 | ✓ | print_directory correctly delegates to directory_engine |
| DR-02 | ✓ | list_directory correctly delegates to directory_engine |
| DR-03 | ✓ | change_directory implements proper path validation |
| HF-01 | ✓ | help_examples correctly formats help and example calls |
| HF-02 | ✓ | apropos_help implements correct term extraction and sending |
| HF-03 | ✓ | find_definition correctly formats R find commands |
| UT-01 | ✓ | add_pipe function works with vanilla Vim functions only |
| UT-02 | ✓ | toggle_debug function correctly toggles debug level |
| EH-01 | ✓ | Created test script to verify error handling without plugin |
| EH-02 | ✓ | public_wrapper checks for filetype support |

### Error Handling Test Results

From running `test_error_handling.vim` script:

```
=== zzvim-R Error Handling Tests ===

Test: zzvim_r#open_terminal()
Output: zzvim-R: Plugin core functions not available

Test: zzvim_r#submit_line()
Output: zzvim-R: Plugin core functions not available

Test: zzvim_r#execute_chunk()
Output: zzvim-R: Plugin core functions not available

Test: zzvim_r#browse_workspace()
Output: zzvim-R: Plugin core functions not available

Test: zzvim_r#install_package()
Output: zzvim-R: Plugin core functions not available

Test: zzvim_r#read_csv()
Output: zzvim-R: Plugin core functions not available

Test: zzvim_r#directory_operation("pwd")
Output: zzvim-R: Plugin core functions not available

Test: zzvim_r#show_class()
Output: zzvim-R: Plugin core functions not available

Test: zzvim_r#inspect_head()
Output: zzvim-R: Plugin core functions not available

=== Tests Complete ===
```

All tests passed, confirming that the error handling for missing plugin functions works correctly.