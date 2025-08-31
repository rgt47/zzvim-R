# Test file for zzvim-R in Neovim
# This file tests various R constructs and linting scenarios

# Good code
library(dplyr)
data(mtcars)

# Code that may trigger style warnings
x<-5
y =10

# Function definition (should be detected as block by zzvim-R)
my_function <- function(x, y) {
  result <- x + y
  return(result)
}

# Pipe operation (tests continuation detection)
result <- mtcars %>%
  filter(mpg > 20) %>%
  select(mpg, cyl, disp)

# Backtick function (tests recent bug fix)
column_names <- sapply(mtcars, `[[`, 1)

# Control structure (should be detected as block)
if (nrow(mtcars) > 0) {
  print("Data has rows")
} else {
  print("No data")
}

# Simple assignment
final_result <- mean(mtcars$mpg)