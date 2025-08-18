# Test direct single line execution
library(ggplot2)
head(iris)
x <- 5

# Test multi-line block (should use temp file)
my_function <- function(data) {
    result <- head(data)
    return(result)
}