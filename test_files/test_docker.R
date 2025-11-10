# Test file for Docker terminal integration
# Testing zzvim-R Docker functionality

# Basic R operations
x <- 1:10
print(x)

# Data frame creation
df <- data.frame(
  name = c("Alice", "Bob", "Charlie"),
  age = c(25, 30, 35),
  score = c(85, 90, 88)
)

# Print structure
str(df)

# Summary statistics
summary(df$age)

# Test function definition
calculate_mean <- function(numbers) {
  sum(numbers) / length(numbers)
}

# Call function
result <- calculate_mean(x)
print(paste("Mean:", result))

# Test if Docker environment works
cat("\nR Version:\n")
R.version.string

cat("\nWorking Directory:\n")
getwd()

cat("\nInstalled Packages:\n")
head(installed.packages()[, c("Package", "Version")], 10)

# Test tidyverse availability (if using rocker/tidyverse image)
if ("dplyr" %in% rownames(installed.packages())) {
  library(dplyr)

  # Test pipe operator
  filtered_df <- df %>%
    filter(age > 25) %>%
    arrange(desc(score))

  print(filtered_df)
}

# Test multi-line assignment with backticks
if (ncol(df) > 0) {
  col_names <- sapply(df, `class`)
  print(col_names)
}

cat("\nDocker terminal test complete!\n")
