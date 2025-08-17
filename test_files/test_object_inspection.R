# =============================================================================
# Object Inspection Test Data for zzvim-R
# =============================================================================
# This file creates test objects to verify object browser functionality
# Usage: Execute this file in R, then test object inspection commands

cat("Creating test objects for object inspection...\n")

# 1. Data frames of different sizes
small_df <- data.frame(
    id = 1:3,
    name = c("Alice", "Bob", "Charlie"),
    score = c(85, 92, 78)
)

large_df <- data.frame(
    x = rnorm(50),
    y = runif(50), 
    category = sample(letters[1:3], 50, replace = TRUE),
    date = seq.Date(as.Date("2023-01-01"), by = "day", length.out = 50)
)

# 2. Vectors of different types and sizes
short_vector <- 1:5
long_vector <- 1:100
char_vector <- c("apple", "banana", "cherry")
logical_vector <- c(TRUE, FALSE, TRUE, TRUE)

# 3. Lists with nested structure
simple_list <- list(a = 1:3, b = "hello", c = TRUE)
nested_list <- list(
    numbers = 1:10,
    data = small_df,
    meta = list(
        created = Sys.Date(),
        version = "test"
    )
)

# 4. Statistical objects
test_data <- data.frame(x = rnorm(30), y = rnorm(30))
test_data$y <- 2 * test_data$x + rnorm(30, 0, 0.5)
linear_model <- lm(y ~ x, data = test_data)

# 5. Matrices  
small_matrix <- matrix(1:12, nrow = 3, ncol = 4)
large_matrix <- matrix(rnorm(200), nrow = 20, ncol = 10)

# 6. Functions
test_function <- function(x, y = 2) {
    return(x^y + sqrt(abs(x)))
}

# 7. Load built-in datasets for additional testing
data(mtcars)
data(iris) 

cat("\n=== Test Objects Created ===\n")
cat("Data frames: small_df, large_df, mtcars, iris\n")
cat("Vectors: short_vector, long_vector, char_vector, logical_vector\n") 
cat("Lists: simple_list, nested_list\n")
cat("Models: linear_model\n")
cat("Matrices: small_matrix, large_matrix\n")
cat("Functions: test_function\n")
cat("=============================\n")

cat("\nTesting Instructions:\n")
cat("1. Use <LocalLeader>' for workspace overview\n")
cat("2. Place cursor on object names above and use <LocalLeader>i\n")
cat("3. Try commands: :RWorkspace, :RInspect mtcars, :RInspect linear_model\n")
cat("4. Test different object types to verify smart inspection\n\n")

# Test the workspace overview manually
cat("Manual workspace check:\n")
for(obj in ls()) {
    cat(obj, ":", class(get(obj))[1], "\n")
}