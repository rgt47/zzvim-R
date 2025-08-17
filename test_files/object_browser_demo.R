# Object Browser Demo and Testing Script
# =====================================
# This script creates a variety of R objects to demonstrate the object browser

# Load required libraries
library(datasets)
if (require(dplyr, quietly = TRUE)) {
    cat("dplyr loaded for enhanced data manipulation\n")
}

# 1. Simple vectors
numbers <- 1:20
letters_vec <- letters[1:10]
logical_vec <- c(TRUE, FALSE, TRUE, TRUE, FALSE)

# 2. Data frames of different sizes
small_df <- data.frame(
    id = 1:5,
    name = c("Alice", "Bob", "Charlie", "Diana", "Eve"),
    score = c(85, 92, 78, 96, 81)
)

large_df <- data.frame(
    x = rnorm(100),
    y = runif(100),
    category = sample(letters[1:5], 100, replace = TRUE),
    date = seq.Date(as.Date("2023-01-01"), by = "day", length.out = 100)
)

# 3. Lists with nested structure
nested_list <- list(
    simple_numbers = 1:10,
    mixed_data = list(
        text = "hello world",
        numbers = c(1.1, 2.2, 3.3),
        logical = TRUE
    ),
    dataframe = small_df
)

# 4. Matrices
simple_matrix <- matrix(1:12, nrow = 3, ncol = 4)
large_matrix <- matrix(rnorm(500), nrow = 25, ncol = 20)

# 5. Statistical objects
model_data <- data.frame(
    x = rnorm(50),
    y = rnorm(50)
)
model_data$y <- 2 * model_data$x + rnorm(50, 0, 0.5)
linear_model <- lm(y ~ x, data = model_data)

# 6. Functions
custom_function <- function(x, y = 2) {
    return(x^y + sqrt(abs(x)))
}

# 7. Load built-in datasets for more testing
data(mtcars)
data(iris)

# 8. Create some summary statistics
mtcars_summary <- summary(mtcars)
iris_by_species <- split(iris, iris$Species)

cat("\n", rep("=", 50), "\n", sep="")
cat("OBJECT BROWSER TESTING INSTRUCTIONS\n")
cat(rep("=", 50), "\n\n", sep="")

cat("1. Press <LocalLeader>\" to open the object browser\n")
cat("   (Note: LocalLeader is usually backslash \\)\n\n")

cat("2. You should see a right panel with numbered objects:\n")
cat("   • Vectors with length information\n")
cat("   • Data frames with dimensions (rows×cols)\n") 
cat("   • Lists with length details\n")
cat("   • Models and functions with class info\n\n")

cat("3. Test navigation:\n")
cat("   • Press numbers 1-9 to quick-inspect objects\n")
cat("   • Use arrow keys and <CR> to inspect at cursor\n")
cat("   • Press ESC to return to object list\n")
cat("   • Press q to close browser entirely\n\n")

cat("4. Test different object types:\n")
cat("   • small_df: Should show structure + head()\n")
cat("   • numbers: Should show first/last elements\n")
cat("   • linear_model: Should show model summary\n")
cat("   • nested_list: Should show list structure\n\n")

cat("5. Expected behavior:\n")
cat("   • Browser opens instantly on right side\n")
cat("   • No 'Press ENTER' prompts\n") 
cat("   • Smooth navigation between objects\n")
cat("   • Detailed inspection shows appropriate info\n\n")
  
cat("Happy testing! 🎯\n")
