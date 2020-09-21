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
##'   \code{filename = "*.csv"} to match all csv files (dynamically
##'   computed on each release).
##'
##' @param path Optional path in which to store the data.  If omitted
##'   we use \code{\link{datastorr_path}} to generate a reasonable
##'   path.
##'
##' @export
github_release_info <- function(repo, read, private = FALSE, filename = NULL,
                                path = NULL) {
  ## TODO: filename name argument
  if (is.null(path)) {
    path <- datastorr_path(repo)
  }
  ## case for single function types
  if(!is.list(read)) {
    read <- c(read)
  }
  if (length(filename) != length(read) && !is.null(filename)) {
    stop("Each file requires a respective read function")
  } 
  for(read_function in read) {
    assert_function(read_function)
  }

  structure(list(path = path, repo = repo, private = private,
                 filenames = filename, 
                 read = read),
            class = "github_release_info")
}

##' Get release versions
##' @title Get release versions
##' @param info Result of running \code{github_release_info}
##'
##' @param local Should we return local (TRUE) or github (FALSE)
##'   version numbers?  Github version numbers are pulled once per
##'   session only.  The exception is for
##'   \code{github_release_version_current} which when given
##'   \code{local = TRUE} will fall back on trying github if there are
##'   no local versions.
##'
##' @export
##' @author Rich FitzJohn
github_release_versions <- function(info, local = TRUE) {
  R6_datastorr$new(info)$versions(local)
}


##' @rdname github_release_versions
##' @export
github_release_version_current <- function(info, local = TRUE) {
  R6_datastorr$new(info)$version_current(local)
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
github_release_get <- function(info, version = NULL) {
  R6_datastorr$new(info)$get(version)
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
  R6_datastorr$new(info)$del(version)
}
