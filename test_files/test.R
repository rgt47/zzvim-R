# zzvim-R Test File
# This file contains R code to test plugin functionality

# Simple R command
print("Hello from R!")

# Creating test data
test_df <- data.frame(
  id = 1:10,
  value = runif(10),
  group = sample(c("A", "B"), 10, replace = TRUE)
)

# Function to test
test_function <- function(x, y = 10) {
  result <- x * y
  return(result)
}

# Pipe operator example (requires magrittr or dplyr)
# test_df %>%
#   group_by(group) %>%
#   summarize(mean_value = mean(value))