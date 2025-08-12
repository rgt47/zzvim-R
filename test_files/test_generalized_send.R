# Test file for generalized SendToR function

# Simple line (should send just this line)
x <- 5

# Function definition (should send entire function block)
my_function <- function(a, b) {
    result <- a + b
    return(result)
}

# If statement (should send entire if block) 
if (x > 0) {
    print("positive")
    y <- x * 2
} else {
    print("negative")
    y <- x * -1
}

# For loop (should send entire loop)
for (i in 1:5) {
    print(i)
    z <- i^2
}

# While loop (should send entire loop)
while (x < 10) {
    x <- x + 1
    print(x)
}

# Standalone code block (should send entire block)
{
    temp_var <- 100
    final_result <- temp_var / 2
    print(final_result)
}

# Lines inside functions (should send individual lines)
another_function <- function(data) {
    # This line should send individually
    cleaned <- na.omit(data)
    # This line too  
    summary_stats <- summary(cleaned)
    return(summary_stats)
}