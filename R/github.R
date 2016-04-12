##' Information to describe how to process github releases
##'
##' The simplest case is where the data are stored in a single file
##' attached to the release (this is different to the zip/tar.gz files
##' that the web interface displays).  For example, a single csv file.
##' In that case the filename argument can be safely ommited and we'll
##' work it out based on the filename.
##'
##' @title Github release information
##' @param repo Name of the repo in \code{username/repo} format.
##'
##' @param read Function to read the file.  See Details.
##'
##' @param private Is the repository private?  If so authentication
##'   will be required for all actions.  Setting this is optional but
##'   will result in better error messages because of the way GitHub
##'   returns not found/404 (rather than forbidden/403) errors when
##'   accessing private repositories without authorisation.
##'
##' @param filename Optional filename.  If omitted, all files in the
##'   release can be used.  If the filename contains a star ("*") it
##'   will be treated as a filename glob.  So you can do
##'   \code{filename="*.csv"} to match all csv files (dynamically
##'   computed on each release).
##'
##' @param path Optional path in which to store the data.  If omitted
##'   we use \code{\link{datastorr_path}} to generate a reasonable
##'   path.
##'
##' @export
github_release_info <- function(repo, read,
                                private=FALSE,
                                filename=NULL,
                                path=NULL) {
  if (is.null(path)) {
    path <- datastorr_path(repo)
  }
  if (length(filename) > 1L) {
    stop("Multiple filenames not yet handled")
  }
  assert_function(read)
  structure(list(path=path, repo=repo, private=private,
                 filename=filename, read=read),
            class="github_release_info")
}

##' Get release versions
##' @title Get release versions
##' @param info Result of running \code{github_release_info}
##'
##' @param local Should we return local (TRUE) or github (FALSE)
##'   version numbers?  Github version numbers are pulled once per
##'   session only.  The exception is for
##'   \code{github_release_version_current} which when given
##'   \code{local=TRUE} will fall back on trying github if there are
##'   no local versions.
##'
##' @export
##' @author Rich FitzJohn
github_release_versions <- function(info, local=TRUE) {
  if (local) {
    storr_github_release(info)$list()
  } else {
    rev(names(github_api_cache(info$private)$get(info$repo)))
  }
}

##' @rdname github_release_versions
##' @export
github_release_version_current <- function(info, local=TRUE) {
  v <- github_release_versions(info, local)
  if (length(v) == 0L && local) {
    v <- github_release_versions(info, FALSE)
  }
  if (length(v) == 0L) {
    NULL
  } else {
    v[[length(v)]]
  }
}

##' Get a version of a data set, downloading it if necessary.
##' @title Get data
##' @param info Result of running \code{github_release_info}
##'
##' @param version Version to fetch.  If \code{NULL} it will get the
##'   current version as returned by
##'   \code{github_release_version_current()}
##'
##' @export
github_release_get <- function(info, version=NULL) {
  if (is.null(version)) {
    version <- github_release_version_current(info)
  }
  storr_github_release(info)$get(version)
}

##' Delete a local copy of a version (or all local copies).  Note that
##' that does not affect the actual github release in any way!.
##'
##' @title Delete version
##'
##' @param info Result of running \code{github_release_info}
##'
##' @param version Version to delete.  If \code{NULL} it will delete
##'   the entire storr
##'
##' @export
github_release_del <- function(info, version) {
  st <- storr_github_release(info)
  if (is.null(version)) {
    st$driver$destroy()
  } else {
    st$del(version)
  }
}

## This is the workhorse thing. We hit the release database (hopefully
## preserved) and from that get the proper url.  Using the browser url
## because the API url requires passing a "application/octet-stream"
## through to the GET.
fetch_hook_github_release <- function(info) {
  ## fetch_hook_download(function(key, namespace) )
  ## TODO: Some of the difficulty here will vanish when
  furl <- function(key, namespace) {
    dat <- github_api_cache(info$private)$get(info$repo)
    x <- dat[[strip_v(key)]]
    if (is.null(x)) {
      stop("No such release ", key)
    }
    files <- vcapply(x$assets, "[[", "name")
    if (is.null(info$filename)) {
      if (length(files) == 1L) {
        i <- 1L
      } else {
        stop("Multiple files not yet handled and no filename given")
      }
    } else {
      i <- match(info$filename, files)
      if (is.na(i)) {
        # TODO: this does not report found filename
        stop(sprintf("File %s not found in release (did find: )",
                     info$filename, paste(files, collapse=", ")))
      }
    }
    x$assets[[i]]$browser_download_url
  }
  fetch_hook_download(furl, info$read)
}

storr_github_release <- function(info) {
  storr::storr_external(storr::driver_rds(info$path),
                        fetch_hook_github_release(info))
}
