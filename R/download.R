## A file downloader that can (a) handle https and (b) actually fail
## when the download fails.  Not sure why that combination is so hard,
## but here it is:
##
## TODO: rewrite to use curl only, possibly with gabor's progress bar
## package.
download_file <- function(url, ..., dest = tempfile(), overwrite = FALSE,
                          verbose = TRUE, binary = FALSE) {
  content <- httr::GET(url,
                       httr::write_disk(dest, overwrite),
                       if (verbose) httr::progress("down"),
                       if (binary) httr::accept("application/octet-stream"),
                       ...)
  cat("\n")
  code <- httr::status_code(content)
  if (code >= 300L) {
    stop(DownloadError(url, code))
  }
  dest
}

DownloadError <- function(url, code) {
  msg <- sprintf("Downloading %s failed with code %d", url, code)
  structure(list(message=msg, call=NULL),
            class=c("DownloadError", "error", "condition"))
}
