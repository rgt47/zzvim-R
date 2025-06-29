# Test file for new RStudio-like smart features in zzvim-R

# 1. FUNCTION BLOCK EXECUTION (existing feature)
# Place cursor on the function definition line and press <CR>
calculate_mean <- function(x, na.rm = TRUE) {
  if (na.rm) {
    result <- mean(x, na.rm = TRUE)
  } else {
    result <- mean(x)
  }
  return(result)
}

# 2. SMART BLOCK EXECUTION (if/for/while)
# Place cursor on the if statement and press <CR>
if (TRUE) {
  print("This is a simple if block")
  x <- 1 + 1
  print(paste("Result:", x))
}

# More complex if-else block
if (runif(1) > 0.5) {
  message("Random number was greater than 0.5")
  result <- "high"
} else {
  message("Random number was less than or equal to 0.5")
  result <- "low"
}

# For loop block
for (i in 1:3) {
  print(paste("Iteration:", i))
  temp <- i * 2
  print(paste("Double:", temp))
}

# While loop block
counter <- 1
while (counter <= 3) {
  print(paste("Counter:", counter))
  counter <- counter + 1
}

# 3. PIPE CHAIN EXECUTION
# Place cursor anywhere in the pipe chain and press <CR>
library(dplyr)

# Simple pipe chain
result1 <- mtcars %>%
  filter(mpg > 20) %>%
  select(mpg, wt, hp) %>%
  arrange(desc(mpg))

# Complex pipe chain with function arguments spanning lines
result2 <- iris %>%
  filter(
    Species == "setosa",
    Sepal.Length > 4.5
  ) %>%
  mutate(
    Sepal.Ratio = Sepal.Length / Sepal.Width,
    Petal.Ratio = Petal.Length / Petal.Width
  ) %>%
  group_by(Species) %>%
  summarise(
    mean_sepal = mean(Sepal.Length),
    mean_petal = mean(Petal.Length),
    .groups = "drop"
  )

# Pipe chain starting mid-assignment
processed_data <- iris %>%
  filter(Species != "virginica") %>%
  head(10)

# 4. ASSIGNMENT WITH OUTPUT
# Place cursor on assignment lines and press <CR> - should show the result
simple_var <- 42
vector_data <- c(1, 2, 3, 4, 5)
matrix_data <- matrix(1:12, nrow = 3)
df_data <- data.frame(x = 1:5, y = letters[1:5])

# 5. REGULAR LINES (should work as before)
# These should just execute the single line
print("This is a regular print statement")
summary(mtcars)
head(iris)

# Comments should also work normally
# This is just a comment line

# 6. MIXED SCENARIOS
# Complex nested structures
nested_example <- function(data) {
  if (nrow(data) > 0) {
    result <- data %>%
      mutate(new_col = ifelse(
        x > mean(x),
        "above_mean",
        "below_mean"
      )) %>%
      group_by(new_col) %>%
      summarise(count = n())
    
    for (i in 1:nrow(result)) {
      print(paste(result$new_col[i], ":", result$count[i]))
    }
    
    return(result)
  } else {
    return(NULL)
  }
}