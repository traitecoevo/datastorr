##' Storr hook for downloading files as an external resource
##' @title Hook for downloading files
##' @param furl Function to convert \code{key, namespace} into a URL.
##' @param fread Function for converting \code{filename} into an R
##' object.
##' @seealso \code{\link{driver_external}}
##' @export
fetch_hook_download <- function(furl, fread) {
  assert_function(url)
  assert_function(fread)
  function(key, namespace) {
    url <- furl(key, namespace)
    dest <- download_file(url)
    on.exit(file.remove(dest))
    fread(dest)
  }
}
