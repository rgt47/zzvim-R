# Object Browser Testing Checklist

## Pre-Testing Setup ✅

```bash
# Ensure you're on the feature branch
git branch  # Should show * feature/object-browser

# Start testing session
vim test_files/object_browser_demo.R
```

## Core Functionality Tests

### 1. Basic Setup
- [ ] File detected as R filetype (`:echo &filetype` should show 'r')
- [ ] Start R terminal: `<LocalLeader>r` (usually `\r`)
- [ ] Terminal opens and R starts successfully
- [ ] Execute some lines from demo file with `<CR>`

### 2. Object Browser Launch
- [ ] Press `<LocalLeader>"` (usually `\"`)
- [ ] Right-side panel opens (40 columns wide)
- [ ] Status message appears: "R Object Browser | Numbers 1-9: inspect..."
- [ ] Panel shows "[R Objects]" as buffer name

### 3. Empty Workspace Test
- [ ] Try browser with empty workspace (should show "No objects in workspace")
- [ ] Clear workspace: `:RRm` then try browser again

### 4. Object Creation and Display
```r
# Execute these lines one by one with <CR>:
x <- 1:10
df <- data.frame(a=1:5, b=letters[1:5])
big_vec <- 1:100
my_list <- list(nums=1:5, text="hello")
```
- [ ] Press `<LocalLeader>"` to open browser
- [ ] Objects appear numbered 1-4
- [ ] Shows types: `x (integer length=10)`, `df (data.frame 5x2)`, etc.

### 5. Navigation Tests
- [ ] Press `1` - should inspect first object (x)
- [ ] Press `ESC` - should return to object list
- [ ] Use arrow keys to move to different object
- [ ] Press `<CR>` - should inspect object at cursor
- [ ] Press `q` - should close browser entirely

### 6. Object Inspection Details
- [ ] Data frame inspection shows structure + head()
- [ ] Long vector shows first/last 10 elements
- [ ] List shows nested structure
- [ ] All inspections include class information

### 7. Error Handling
- [ ] Try browser in non-R file (should show error)
- [ ] Try browser without R terminal (should show error message)
- [ ] Try number keys beyond available objects (should handle gracefully)

## Advanced Tests

### 8. Complex Objects
```r
# Create and test these:
model <- lm(mpg ~ wt, mtcars)
big_matrix <- matrix(rnorm(100), 10, 10)
nested <- list(df=mtcars, models=list(lm1=model))
```
- [ ] All complex objects display appropriately
- [ ] Model inspection shows summary
- [ ] Matrix shows structure
- [ ] Nested list shows hierarchy

### 9. Performance Tests
```r
# Create many objects:
for(i in 1:15) assign(paste0("obj",i), rnorm(100))
```
- [ ] Browser loads quickly with many objects
- [ ] All objects numbered and accessible
- [ ] Navigation remains smooth

### 10. Integration Tests
- [ ] Existing `<CR>` smart submission still works
- [ ] Other `<LocalLeader>` mappings unaffected (`h`, `s`, `d`, etc.)
- [ ] Can switch between browser and main buffer smoothly
- [ ] Multiple R files have independent object browsers

## User Experience Tests

### 11. Workflow Test
```r
# Typical analysis workflow:
library(dplyr)
data <- mtcars %>% 
  filter(mpg > 20) %>%
  mutate(efficiency = mpg/wt)
model <- lm(efficiency ~ hp, data)
summary_stats <- summary(data)
```
- [ ] Execute workflow step by step
- [ ] Open browser at each stage to see objects accumulate
- [ ] Inspect different object types as they're created

### 12. vim-peekaboo Similarity
- [ ] Browser behavior feels similar to vim-peekaboo
- [ ] `"` key mapping is intuitive and accessible
- [ ] ESC/q closing behavior matches expectations
- [ ] Right-side positioning works well

## Bug Hunting

### 13. Edge Cases
- [ ] Objects with special characters in names
- [ ] Very large objects (test performance)
- [ ] Objects with complex nested structures
- [ ] R workspace with 20+ objects

### 14. Error Recovery
- [ ] What happens if R session dies while browser open?
- [ ] What if temp file creation fails?
- [ ] Browser behavior with slow R responses?

## Final Assessment

### 15. Overall Experience
- [ ] Feature feels polished and ready for daily use
- [ ] No major usability issues
- [ ] Integrates well with existing workflow
- [ ] Performance is acceptable
- [ ] Error messages are helpful

### 16. Decision Criteria
- [ ] **MERGE**: All tests pass, ready for production
- [ ] **ITERATE**: Minor issues need fixing
- [ ] **MAJOR REVISION**: Significant problems found

---

## Notes Section
```
Add any issues, suggestions, or observations here:

- 
- 
- 
```

## Quick Commands for Testing

```vim
" Check object browser function exists:
:echo ZzvimRTestObjectBrowser()

" Manual browser launch:
:RObjectBrowser

" Check current filetype:
:echo &filetype

" Check R terminal:
:RShowTerminal
```