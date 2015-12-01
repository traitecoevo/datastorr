vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}

assert_function <- function(x, name=deparse(substitute(x))) {
  if (!is.function(x)) {
    stop(sprintf("%s must be a function", name), call. = FALSE)
  }
}
