vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}

assert_function <- function(x, name = deparse(substitute(x))) {
  if (!is.function(x)) {
    stop(sprintf("%s must be a function", name), call. = FALSE)
  }
}

assert_file <- function(filename) {
  if(!file.exists(filename)) {
    stop(sprintf("%s doesn't exist or cannot be found", filename, call. = FALSE))
  }
}

verify_files <- function(files) {
  for(filename in files) {
    assert_file(filename)
  }
}

fill_info_files <- function(info, filenames) {
  if(is.null(info$filenames)) {
    info$filenames <- filenames
  }
  for(filename in info$filenames) {
    if (grepl("/", filename, fixed = TRUE)) {
      stop("Expected path-less info$filename")
    }
  }
}

create_version_filename = function(version, filename) {
  paste0(version, "_", filename)
}

get_version_regex <- function(version) {
  version_values <- unlist(stringr::str_match_all(version, pattern="\\d"))
  paste0("^", version_values[1], "\\.", version_values[2], "\\.", version_values[3])
}

## From dide-tools/encryptr:
prompt_confirm <- function(msg = "continue?", valid = c(n = FALSE, y = TRUE),
                           default = names(valid)[[1]]) {
  valid_values <- names(valid)
  msg <- sprintf("%s [%s]: ", msg,
                 paste(c(toupper(default), setdiff(valid_values, default)),
                       collapse = "/"))
  repeat {
    x <- trimws(tolower(readline(prompt = msg)))
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
find_package_root <- function(stop_by = "/") {
  root <- normalizePath(stop_by, mustWork = TRUE)
  f <- function(path) {
    if (file.exists(file.path(path, "DESCRIPTION"))) {
      return(path)
    }
    if (normalizePath(path, mustWork = TRUE) == root) {
      stop("Hit the root without finding a package")
    }
    Recall(file.path("..", path))
  }
  normalizePath(f("."), mustWork = TRUE)
}


`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}
