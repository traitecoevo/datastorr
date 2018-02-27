vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}

assert_function <- function(x, name=deparse(substitute(x))) {
  if (!is.function(x)) {
    stop(sprintf("%s must be a function", name), call. = FALSE)
  }
}

## From dide-tools/encryptr:
prompt_confirm <- function(msg="continue?", valid=c(n=FALSE, y=TRUE),
                           default=names(valid)[[1]]) {
  valid_values <- names(valid)
  msg <- sprintf("%s [%s]: ", msg,
                 paste(c(toupper(default), setdiff(valid_values, default)),
                       collapse="/"))
  repeat {
    x <- trimws(tolower(readline(prompt=msg)))
    if (!nzchar(x)) {
      x <- default
    }
    if (x %in% valid_values) {
      return(valid[[x]])
    } else {
      cat("Invalid choice\n")
    }
  }
}

dquote <- function(x) {
  sprintf('"%s"', x)
}

## Will this work on windows?
find_package_root <- function(stop_by="/") {
  root <- normalizePath(stop_by, mustWork=TRUE)
  f <- function(path) {
    if (file.exists(file.path(path, "DESCRIPTION"))) {
      return(path)
    }
    if (normalizePath(path, mustWork=TRUE) == root) {
      stop("Hit the root without finding a package")
    }
    Recall(file.path("..", path))
  }
  normalizePath(f("."), mustWork=TRUE)
}


`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}
