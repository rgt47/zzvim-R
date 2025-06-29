# Test file for function block detection

# Simple function definition
aa <- function(x) {
  result <- x * 2
  return(result)
}

# Multi-line function definition
bb <- function(x, y = 10) {
  temp <- x + y
  if (temp > 0) {
    result <- temp * 2
  } else {
    result <- 0
  }
  return(result)
}

# Function with nested braces
cc <- function(data) {
  processed <- data %>%
    filter(x > 0) %>%
    mutate(
      new_col = case_when(
        y > 5 ~ "high",
        y <= 5 ~ "low"
      )
    )
  return(processed)
}

# Regular variable assignment (should not trigger function block)
simple_var <- 42

# Another regular line
print("This is not a function")
102
2
43
