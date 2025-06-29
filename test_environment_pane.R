# Test file for Environment Pane functionality
# Use <LocalLeader>we to toggle the environment pane

# Create some test objects to populate the workspace

# Simple variables
x <- 42
name <- "test"
flag <- TRUE

# Vectors
numbers <- c(1, 2, 3, 4, 5)
letters_vec <- c("a", "b", "c")

# Data frame
test_df <- data.frame(
  id = 1:10,
  value = runif(10),
  category = sample(c("A", "B", "C"), 10, replace = TRUE)
)

# Matrix
test_matrix <- matrix(1:12, nrow = 3, ncol = 4)

# List
test_list <- list(
  numbers = 1:5,
  text = "hello world",
  nested = list(a = 1, b = 2)
)

# Function
my_function <- function(x, y = 10) {
  return(x + y)
}

# After creating objects:
# 1. Press <LocalLeader>we to open environment pane
# 2. Navigate with arrow keys
# 3. Press <CR> on an object name to inspect it
# 4. Press 'r' to refresh the environment
# 5. Press 'q' or <Esc> to close the environment pane
# 6. Execute more code and watch the environment auto-refresh

# Test auto-refresh by creating more objects
z <- 100
new_data <- data.frame(x = 1:5, y = 5:1)

# The environment pane should automatically update when you execute code!