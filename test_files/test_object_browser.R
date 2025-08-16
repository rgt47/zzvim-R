# Test file for object browser functionality
# This creates various R objects to test the browser

# Create some test objects
library(datasets)

# Vector
test_vector <- c(1, 2, 3, 4, 5)

# Data frame
test_df <- data.frame(
  x = 1:10,
  y = letters[1:10],
  z = rnorm(10)
)

# List
test_list <- list(
  numbers = 1:5,
  letters = letters[1:3],
  dataframe = test_df
)

# Matrix
test_matrix <- matrix(1:12, nrow = 3, ncol = 4)

# Function
test_function <- function(x) {
  return(x^2)
}

# Load mtcars for more testing
data(mtcars)

# Print message
cat("Objects created for browser testing\n")
cat("Try pressing <LocalLeader>\" to open the object browser\n")