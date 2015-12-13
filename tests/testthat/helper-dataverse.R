skip_if_no_downloads <- function() {
  skip_unless_internet()
  if (Sys.getenv("DATASTORR_SKIP_DOWNLOADS") == "") {
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
  if (inherits(github_token(), "request")) {
    return()
  }
  skip("No GITHUB_TOKEN set")
}
has_internet <- function() {
  !is.null(suppressWarnings(nsl("www.google.com")))
}

## I don't think that this wants to be part of the main bit of the
## package as it's a bit savage but it'll do for now:
github_api_delete_all_releases <- function(info, yes=!interactive()) {
  d <- github_api_releases(info)
  for (x in d) {
    github_api_release_delete(info, I(x$tag_name), yes)
  }
}
