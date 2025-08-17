# Object Inspection Testing Checklist

## Automated Tests

### 1. Function Tests
- [ ] `s:RWorkspaceOverview()` exists and callable
- [ ] `s:RInspectObject()` exists and callable  
- [ ] Error handling for empty object names

### 2. Command Tests
- [ ] `:RWorkspace` command exists
- [ ] `:RInspect` command exists
- [ ] `:RInspect [object]` with argument works

### 3. Key Mapping Tests (in R files)
- [ ] `<LocalLeader>'` mapping exists  
- [ ] `<LocalLeader>i` mapping exists
- [ ] Mappings only active in R/Rmd/Quarto files

## Manual Functional Tests

### 4. Workspace Overview (`<LocalLeader>'` or `:RWorkspace`)
- [ ] Shows header: "=== Workspace ==="
- [ ] Lists all objects with format: "name : class"
- [ ] Shows footer: "================="
- [ ] Handles empty workspace gracefully
- [ ] Works with large numbers of objects (20+)

### 5. Object Inspection (`<LocalLeader>i` or `:RInspect`)

#### Data Frames
- [ ] **Small data frame**: Shows glimpse() output (if dplyr available)
- [ ] **Large data frame**: Shows glimpse() with all columns
- [ ] **Without dplyr**: Falls back to str() gracefully
- [ ] **Built-in datasets**: mtcars, iris work correctly

#### Vectors  
- [ ] **Short vectors**: Shows str() output
- [ ] **Long vectors**: Shows str() output 
- [ ] **Character vectors**: Displays properly
- [ ] **Logical vectors**: Shows TRUE/FALSE values

#### Lists
- [ ] **Simple lists**: Shows str() structure
- [ ] **Nested lists**: Shows hierarchical structure
- [ ] **Mixed-type lists**: Handles different element types

#### Models
- [ ] **Linear models**: Shows model structure
- [ ] **Statistical objects**: Displays appropriately

#### Functions
- [ ] **User functions**: Shows function structure
- [ ] **Built-in functions**: Handles gracefully

#### Error Cases
- [ ] **Non-existent objects**: Shows "Not found: objectname"
- [ ] **Empty object name**: Shows error message
- [ ] **No R terminal**: Handles gracefully

### 6. Integration Tests

#### Terminal Integration
- [ ] Works with buffer-specific terminals
- [ ] Output appears in correct R terminal
- [ ] No conflicts with other R commands
- [ ] Silent execution (no "Press ENTER" prompts)

#### File Type Integration  
- [ ] Works in .R files
- [ ] Works in .Rmd files  
- [ ] Works in .qmd files
- [ ] Disabled in non-R files

#### Workflow Integration
- [ ] Doesn't interfere with existing object inspection (`<LocalLeader>h`, `<LocalLeader>s`, etc.)
- [ ] Works alongside other plugin features
- [ ] Maintains cursor position appropriately

### 7. Performance Tests

#### Large Workspaces
- [ ] **50+ objects**: Workspace overview loads quickly
- [ ] **Large objects**: Inspection doesn't hang Vim
- [ ] **Complex nested objects**: Handles gracefully

#### Edge Cases  
- [ ] **Very long object names**: Displays properly
- [ ] **Objects with special characters**: Handles correctly
- [ ] **Unicode object names**: Works if R supports

### 8. User Experience Tests

#### Output Quality
- [ ] **Clean formatting**: No command echoing visible
- [ ] **Readable output**: Well-formatted, clear headers
- [ ] **Appropriate detail level**: Not too verbose, not too brief
- [ ] **Consistent style**: Matches rest of plugin

#### Workflow Efficiency
- [ ] **Fast execution**: Commands execute immediately
- [ ] **Intuitive operation**: Easy to understand and use  
- [ ] **Helpful feedback**: Clear error messages when needed

## Testing Commands

### Run Automated Tests
```vim
:source test_files/test_object_inspection.vim
```

### Create Test Objects
```vim
:edit test_files/test_object_inspection.R
<LocalLeader>r
```
Then execute the R file contents.

### Manual Testing Sequence
1. Open R file: `:edit test.R`
2. Start R terminal: `<LocalLeader>r`
3. Create objects: Execute test_object_inspection.R
4. Test workspace: `<LocalLeader>'`
5. Test inspection: Put cursor on object name, press `<LocalLeader>i`
6. Test commands: `:RWorkspace`, `:RInspect mtcars`

## Expected Results

### Workspace Overview Output
```
=== Workspace ===
small_df : data.frame
long_vector : integer  
linear_model : lm
test_function : function
=================
```

### Object Inspection Output (with dplyr)
```
=== mtcars ===
Rows: 32
Columns: 11
$ mpg  <dbl> 21.0, 21.0, 22.8, 21.4, 18.7, 18.1
$ cyl  <dbl> 6, 6, 4, 6, 8, 6
...
```

### Object Inspection Output (without dplyr)
```
=== mtcars ===
'data.frame': 32 obs. of 11 variables:
 $ mpg : num 21 21 22.8 21.4 18.7 18.1
 $ cyl : num 6 6 4 6 8 6
...
```