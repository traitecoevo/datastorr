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
##' @param filename Optional filename.  If omitted, all files in the
##'   release can be used.  If the filename contains a star ("*") it
##'   will be treated as a filename glob.  So you can do
##'   \code{filename="*.csv"} to match all csv files (dynamically
##'   computed on each release).
##'
##' @param path Optional path in which to store the data.  If omitted
##'   we use \code{rappdirs} to generate a reasonable path.
##'
##' @export
github_release_info <- function(repo, read,
                                filename=NULL,
                                path=NULL) {
  if (is.null(path)) {
    path <- github_release_path(repo)
  }
  if (length(filename) > 1L) {
    stop("Multiple filenames not yet handled")
  }
  assert_function(read)
  structure(list(path=path, repo=repo, filename=filename, read=read),
            class="github_release_info")
}

##' @importFrom rappdirs user_data_dir
github_release_path <- function(repo) {
  rappdirs::user_data_dir(file.path("dataverse", repo))
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
    rev(names(storr_github_release_versions()$get(info$repo)))
  }
}

##' @rdname github_release_versions
##' @export
github_release_version_current <- function(info, local=TRUE) {
  v <- github_release_versions(info, local)
  if (length(v) == 0L && local) {
    v <- github_release_versions(info, FALSE)
  }
  v[[length(v)]]
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

##' Delete a local copy of a version (or the entire thing).
##' @title Delete version
##' @param info Result of running \code{github_release_info}
##' @param version Version to delete.  If \code{NULL} it will delete the entire storr
##' @export
github_release_del <- function(info, version) {
  st <- storr_github_release(info)
  if (is.null(version)) {
    st$driver$destroy()
  } else {
    st$del(version)
  }
}

storr_github_release <- function(info) {
  storr::storr_external(storr::driver_rds(info$path),
                        fetch_hook_github_release(info))
}

## TODO: automatic expiry please (then we could use the global cache
## perhaps).
##
## TODO: would it be easier to just use memoisation here rather than
## this approach? Not sure Seems like it would be.  But then we also
## have to create the global memoisation cache which is more annoying.
##
## Internal place to stick things for the lifetime of a session.
local <- new.env(parent=emptyenv())
storr_github_release_versions <- function() {
  f <- function(key, namespace) {
    ## TODO: This will be more nicely handled with the pagnation
    ## feature of Gabor's gh package but I'd rather that hits CRAN
    ## before depending on it.  Replace the following four lines with:
    ##   ret <- gh::gh("/repos/:repo/releases", repo=key)
    url <- sprintf("https://api.github.com/repos/%s/releases", key)
    dat <- httr::GET(url, query=list(per_page=100))
    httr::stop_for_status(dat)
    ret <- httr::content(dat)
    names(ret) <- strip_v(vcapply(ret, "[[", "tag_name"))
    ret
  }
  dr <- storr::driver_environment(local)
  storr::storr_external(dr, f, default_namespace="versions")
}

## This is the workhorse thing. We hit the release database (hopefully
## preserved) and from that get the proper url.  Using the browser url
## because the API url requires passing a "application/octet-stream"
## through to the GET.
fetch_hook_github_release <- function(info) {
  ## fetch_hook_download(function(key, namespace) )
  ## TODO: Some of the difficulty here will vanish when
  furl <- function(key, namespace) {
    dat <- storr_github_release_versions()$get(info$repo)
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
        stop(sprintf("File %s not found in release (did find: )",
                     info$filename, paste(files, collapse=", ")))
      }
    }
    x$assets[[i]]$browser_download_url
  }
  fetch_hook_download(furl, info$read)
}

## Consistently deal with leading vs; we'll just remove them
## everywhere that has them and that way vx.y.z will match x.y.z and
## v.v.  Pretty strict matching though.
strip_v <- function(x) {
  sub("^v([0-9]+([-_.][0-9]+){0,2})", "\\1", x)
}
