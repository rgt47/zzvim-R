# Demo of New Generalized SendToR Functionality

# Regular line - <CR> will send just this line
x <- 10

# Function definition - <CR> will send entire function block
calculate_mean <- function(data) {
    if (is.numeric(data)) {
        result <- mean(data, na.rm = TRUE)
        return(result)
    } else {
        stop("Data must be numeric")
    }
}

# If statement - <CR> will send entire if/else block
if (x > 5) {
    print("x is greater than 5")
    y <- x * 2
} else {
    print("x is 5 or less") 
    y <- x / 2
}

# For loop - <CR> will send entire loop
for (i in 1:3) {
    cat("Iteration:", i, "\n")
    z <- i^2
    print(z)
}

# Inside function body - <CR> will send individual lines
process_data <- function(df) {
    # This line sent individually when cursor here
    cleaned <- na.omit(df)
    # This line sent individually when cursor here  
    summary_stats <- summary(cleaned)
    # This line sent individually when cursor here
    return(summary_stats)
}

# Additional key mappings available:
# <LocalLeader>sf - Force send function block
# <LocalLeader>sl - Force send current line only
# <LocalLeader>sa - Smart auto-detection