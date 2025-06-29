# Smart Execution Demo for zzvim-R Plugin
# This file demonstrates all the smart execution features

# 1. FUNCTION BLOCK EXECUTION
# Place cursor anywhere on lines 7-11 and press <CR>
# The entire function will be executed as a block
calculate_stats <- function(data) {
  mean_val <- mean(data, na.rm = TRUE)
  sd_val <- sd(data, na.rm = TRUE)
  return(list(mean = mean_val, sd = sd_val))
}

# 2. CONTROL STRUCTURE EXECUTION  
# Place cursor on line 15 (if statement) and press <CR>
# The entire if block will be executed
if (TRUE) {
  x <- 10
  y <- 20
  result <- x + y
  print(paste("Sum is:", result))
}

# Place cursor on line 23 (for loop) and press <CR>
# The entire for loop will be executed
for (i in 1:3) {
  print(paste("Iteration:", i))
  temp <- i * 2
  print(paste("Double:", temp))
}

# Place cursor on line 30 (while loop) and press <CR>
# The entire while loop will be executed
counter <- 1
while (counter <= 3) {
  print(paste("Counter:", counter))
  counter <- counter + 1
}

# 3. PIPE CHAIN EXECUTION
# Place cursor anywhere on lines 37-42 and press <CR>
# The entire pipe chain will be executed as one unit
library(dplyr)
mtcars %>%
  filter(mpg > 20) %>%
  select(mpg, hp, wt) %>%
  mutate(hp_per_weight = hp / wt) %>%
  arrange(desc(hp_per_weight))

# Another pipe example - place cursor on any line 45-48
iris %>%
  group_by(Species) %>%
  summarise(mean_sepal = mean(Sepal.Length)) %>%
  arrange(desc(mean_sepal))

# 4. ASSIGNMENT WITH OUTPUT
# Place cursor on line 52 and press <CR>
# Variable will be assigned AND its value displayed
my_data <- c(1, 2, 3, 4, 5)

# Place cursor on line 56 and press <CR>
# Complex assignment with output
summary_stats <- summary(mtcars$mpg)

# Place cursor on line 60 and press <CR>
# Function result assignment with output
test_result <- calculate_stats(c(1, 2, 3, 4, 5, NA))

# 5. REGULAR SINGLE LINE EXECUTION
# These lines execute normally (no smart detection)
print("This is a regular line")
x <- 42
mean(1:10)

# 6. NESTED STRUCTURES
# Place cursor on line 70 (outer if) and press <CR>
# The entire nested structure will be executed
if (x > 30) {
  if (x > 40) {
    print("x is greater than 40")
    for (j in 1:2) {
      print(paste("Nested loop iteration:", j))
    }
  } else {
    print("x is between 30 and 40")
  }
}

# 7. COMPLEX FUNCTION WITH CONTROL STRUCTURES
# Place cursor on line 82 and press <CR>
# The entire function definition will be executed
process_data <- function(values, threshold = 5) {
  result <- c()
  for (val in values) {
    if (val > threshold) {
      result <- c(result, val * 2)
    } else {
      result <- c(result, val)
    }
  }
  return(result)
}

# Test the function (regular execution)
test_values <- c(1, 3, 6, 8, 2, 7)
processed <- process_data(test_values)
print(processed)