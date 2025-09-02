a <- 2
aa <- function(y) {
  x <- y + 1
  x
}

1 + 1 + rnorm(10) + a
library(ggplot2)
ggplot(data = iris, aes(x = Sepal.Length, y = Sepal.Width)) +
  geom_point()
