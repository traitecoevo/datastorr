##' Storr hook for downloading files as an external resource.  This
##' might be useful for other, more general projects.  Just depend on
##' this package (which drags in curl) and use this as the
##' \code{fetch_hook} argument to \code{\link{storr_external}}.
##'
##' @title Hook for downloading files
##'
##' @param furl Function to convert \code{key, namespace} into a URL.
##'   Takes scalar strings for key and namespace and returns a scalar
##'   string URL.  Depending on the application you may not need the
##'   namespace argument but your function must accept it even if it
##'   just ignores it.
##'
##' @param fread Function for converting \code{filename} into an R
##'   object.  \code{filename} will be a scalar character and be a
##'   filename that will exist on the system.  \code{fread} can return
##'   anything and may throw an error if the given file was not in a
##'   valid format.  Functions \code{read.csv}, \code{readRDS} can be
##'   used here as-is (though for the former consider
##'   \code{function(filename) read.csv(filename,
##'   stringsAsFactors=FALSE)}).
##'
##' @param ... Additional parameters that will be passed through to
##'   download the file (via \code{httr::GET}).
##'
##' @seealso \code{\link{storr_external}}
##' @export
fetch_hook_download <- function(furl, fread, ...) {
  assert_function(url)
  assert_function(fread)
  function(key, namespace) {
    url <- furl(key, namespace)
    dest <- download_file(url, ...)
    on.exit(file.remove(dest))
    fread(dest)
  }
}
