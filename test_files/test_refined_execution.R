# Test refined clean execution approach
# Test single line
simple_var <- "hello"

# Test small function (should send line by line)
small_func <- function(x) {
    return(x + 1)
}

# Test larger block (should use minimal source)
large_func <- function(data, col1, col2, filter_val) {
    library(dplyr)
    result <- data %>%
        filter(!!sym(col1) > filter_val) %>%
        select(all_of(c(col1, col2))) %>%
        arrange(desc(!!sym(col1)))
    return(result)
}