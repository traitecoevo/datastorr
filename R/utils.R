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
