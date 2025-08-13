# Test file for parenthesis matching functionality

# Simple function call (should be detected as single unit)
p_load(dplyr)

# Multi-line function call (should be kept together)
data.frame(
  id = 1:10,
  value = runif(10),
  group = sample(c("A", "B"), 10, replace = TRUE)
)

# Complex ggplot call (should be kept together)
ggplot(data = mtcars,
       aes(x = wt, y = mpg)) +
  geom_point()

# Nested function calls
outer_func(
  inner_func(
    x = 5,
    y = 10
  ),
  z = 15
)

# Function definition (should still work with braces)
my_function <- function(x, y = 10) {
  result <- x * y
  return(result)
}

# Control structure (should still work with braces)
if (x > 0) {
  print("positive")
} else {
  print("negative")
}