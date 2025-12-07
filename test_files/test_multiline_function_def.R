# Test case for multi-line function definition bug
t2f <- function(df, filename = NULL,
                sub_dir = "output",
                scolor = "blue!10", verbose = FALSE,
                extra_packages = NULL,
                document_class = "article") {
  # Validate inputs
  if (is.null(filename)) filename <- deparse(substitute(df))
  if (!is.data.frame(df)) stop("`df` must be a dataframe.", call. = FALSE)
  if (nrow(df) == 0) stop("`df` must not be empty.", call. = FALSE)
  if (!is.character(scolor) || length(scolor) != 1) {
    stop("`scolor` must be a single character string.", call. = FALSE)
  }
  if (!is.character(document_class) || length(document_class) != 1) {
    stop("`document_class` must be a single character string.", call. = FALSE)
  }
  if (!is.logical(verbose) || length(verbose) != 1) {
    stop("`verbose` must be a single logical value.", call. = FALSE)
  }

  # The rest of the function would go here...
  print("Function works!")
}

# Test that the function can be called
result <- t2f(mtcars)
