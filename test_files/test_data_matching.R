# Test data file for block matching functionality
# Contains various R code patterns to test parenthesis and brace matching

# === PARENTHESIS MATCHING TEST CASES ===

# Single-line function calls
library(pacman)
p_load(dplyr)
install.packages("ggplot2")

# Multi-line function calls
data.frame(
  id = 1:10,
  value = runif(10),
  group = sample(c("A", "B"), 10, replace = TRUE)
)

# Nested function calls
outer_func(
  inner_func(
    x = 5,
    y = 10
  ),
  z = 15
)

# ggplot with multiple lines
ggplot(data = mtcars,
       aes(x = wt, y = mpg)) +
  geom_point() +
  theme_minimal()

# === BRACE MATCHING TEST CASES ===

# Simple function definition
my_func <- function(x, y = 10) {
  result <- x * y
  return(result)
}

# Function with nested structures
complex_func <- function(data) {
  if (is.null(data)) {
    return(NULL)
  }
  
  for (i in 1:nrow(data)) {
    if (data[i, "value"] > 0) {
      data[i, "category"] <- "positive"
    } else {
      data[i, "category"] <- "negative"
    }
  }
  
  return(data)
}

# Control structures
if (x > 0) {
  print("positive")
} else if (x < 0) {
  print("negative")
} else {
  print("zero")
}

# For loop
for (i in 1:10) {
  print(paste("Iteration:", i))
  if (i > 5) {
    break
  }
}

# While loop
counter <- 1
while (counter <= 5) {
  print(counter)
  counter <- counter + 1
}

# === MIXED CASES ===

# Function definition inside which we have function calls
bb = function(x){
  library(pacman)
  p_load(dplyr)
  p_load(
    ggplot2
  )
  
  result <- data.frame(
    x = x,
    y = x * 2
  )
  
  return(result)
}

# Complex nested structure
process_data <- function(input_data) {
  if (is.data.frame(input_data)) {
    transformed <- input_data %>%
      filter(value > 0) %>%
      mutate(
        new_column = case_when(
          value > 10 ~ "high",
          value > 5 ~ "medium",
          TRUE ~ "low"
        )
      ) %>%
      group_by(category) %>%
      summarise(
        mean_value = mean(value, na.rm = TRUE),
        count = n()
      )
    
    return(transformed)
  } else {
    stop("Input must be a data frame")
  }
}

# === ERROR CASES (for testing error handling) ===

# Missing closing parenthesis (commented to avoid syntax errors)
# p_load(dplyr
# data.frame(x = 1:5

# Missing closing brace (commented to avoid syntax errors)  
# if (x > 0) {
#   print("test")

# === EDGE CASES ===

# Empty parentheses
empty_func()

# Empty braces
if (TRUE) {
}

# Single character lines
{
}

(
)

# Multiple opening/closing on same line
if (x > 0) { print("test") }
func(a, func2(b, c), d)

# Comments and strings with misleading characters
# This comment has (parentheses) and {braces}
text <- "This string has (parens) and {braces} but should not match"

# Escaped characters in strings
pattern <- "function\\(.*\\)\\s*\\{"