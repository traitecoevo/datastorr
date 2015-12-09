skip_if_no_downloads <- function() {
  skip_unless_internet()
  if (Sys.getenv("DATAVERSE_SKIP_DOWNLOADS") == "") {
    return()
  }
  skip("Skipping downloads")
}
skip_unless_internet <- function() {
  if (has_internet()) {
    return()
  }
  skip("No internet :(")
}
skip_if_no_github_token <- function() {
  if (inherits(github_api_token(FALSE), "request")) {
    return()
  }
  skip("No GITHUB_TOKEN set")
}
has_internet <- function() {
  !is.null(suppressWarnings(nsl("www.google.com")))
}
