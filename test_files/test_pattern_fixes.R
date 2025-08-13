# Test file for pattern recognition fixes

# Multi-line function call (should be detected as complete block)
p_load(
       dplyr,
       ggplot2
)

# Function definition
aa = function(y){
  x = y + 1  # This line should be sent individually when inside function
  x          # This line should be sent individually when inside function
}

# Simple statements
1+1
2

# Another multi-line function call
library(
    pacman
)

# Nested function call
result <- transform_data(
    data = my_data,
    func = function(x) {
        x + 1
    }
)