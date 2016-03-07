## A file downloader that can (a) handle https and (b) actually fail
## when the download fails.  Not sure why that combination is so hard,
## but here it is:
download_file <- function(url, ..., dest=tempfile(), overwrite=FALSE) {
  content <- httr::GET(url,
                       httr::write_disk(dest, overwrite),
                       httr::progress("down"), ...)
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
