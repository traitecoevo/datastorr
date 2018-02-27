## This is the simple interface.  The simplest thing to do is to
## assume the same github interface for now.  I like that because it's
## really simple but another, even simpler, approach would be to store
## pointers somewhere and grab files from there.  To some degree that
## can be done more efficiently just with storr though.
##
## TODO: having this support OKFN data packages would seem preferable.
## But I don't know that they have enough of this information in it.

##' Create a lightweight datastorr interface (rather than using the
##' full package approach).  This approach is designed for the
##' "files that don't fit in git" use-case.
##'
##' Note that the package approach is likely to scale better; in
##' particular it allows for the reading function to be arbitrarily
##' complicated, allows for package installation and loading, etc.
##' With this simple interface you will need to document your
##' dependencies carefully.  But it does remove the requirement for
##' making a package and will likely work pretty well as part of an
##' analysis pipeline where your dependencies are well documented
##' anyway.
##' @title Fetch data from a datastorr repository
##' @param repo Either a github repo in the form
##'   \code{<username>/<repo>} (e.g.,
##'   \code{"richfitz/data"} or the path to a json file
##'   on your filesystem.
##' @param path The path to store the data at.  Using \code{NULL} will
##' @param metadata The name of the metadata file within the repo (if
##'   \code{repo} refers to a github repo.  The default is
##'   \code{datastorr.json} at the root of the repository, but any
##'   other filename can be used.
##' @param branch The branch in the repo to use.  Default is
##'   \code{master}.
##' @param private A logical indicating if the repository is private
##'   and therefor if authentication will be needed to access it.
##' @param refetch Refetch the metadata file even if it has already
##'   been downloaded previously.
##' @param version Which version to download (if \code{extended} is
##'   \code{FALSE} -- the default).  By default the most recent
##'   version on the remote, or the current version locally will be
##'   fetched.
##' @param extended Don't fetch the data, but instead return an object
##'   that can query data, versions, etc.
##' @export
##' @examples
##' \dontrun{
##' path <- tempfile()
##' dat <- datastorr("richfitz/data", path, extended=TRUE)
##' dat$list()
##' dat()
##' }
datastorr <- function(repo, path=NULL,
                      metadata="datastorr.json", branch="master",
                      private=FALSE, refetch=FALSE,
                      version=NULL, extended=FALSE) {
  info <- datastorr_info(repo, path, metadata, branch, private, refetch)
  obj <- .R6_datastorr$new(info)
  if (extended) {
    if (!is.null(version)) {
      warning("Ignoring argument 'version'")
    }
    obj
  } else {
    version <- version %||% obj$version_current()
    if (is.null(version)) {
      stop(sprintf("No versions found at '%s'", info$repo))
    }
    obj$get(version)
  }
}

##' @param ... Arguments passed through to \code{datastorr}
##' @param local Return information on local versions?
##' @export
##' @rdname datastorr
datastorr_versions <- function(..., local=TRUE) {
  datastorr(..., extended=TRUE)$versions(local)
}

.R6_datastorr <- R6::R6Class(
  "datastorr",
  public=list(
    info=NULL,
    path=NULL,
    initialize=function(info) {
      self$info <- info
      self$path <- info$path
      lockBinding(quote(info), self)
      lockBinding(quote(path), self)
    },
    get=function(version=NULL) {
      github_release_get(self$info, version)
    },
    versions=function(local=TRUE) {
      github_release_versions(self$info, local)
    },
    version_current=function(local=TRUE) {
      github_release_version_current(self$info, local)
    },
    del=function(version) {
      github_release_del(self$info, version)
    }))

##' Create a relase for a simple datastorr (i.e., non-package based).
##'
##' @title Release data to a datastorr repository
##'
##' @inheritParams datastorr
##'
##' @param version A version number for the new version.  Should be of
##'   the form x.y.z, and may or may not contain a leading "v" (one
##'   will be added in any case).
##'
##' @param description Optional text description for the release.  If
##'   this is omitted then GitHub will display the commit message from
##'   the commit that the release points at.
##'
##' @param filename Filename to upload; optional if in
##'   \code{datastorr.json}.  If listed, \code{filename} can be
##'   different but the file will be renamed on uploading.  If given
##'   but not in \code{info}, the uploaded file will be
##'   \code{basename(filename)} (i.e., the directory will be
##'   stripped).
##'
##' @param target The SHA or tag to attach the release to.  By
##'   default, will use the current HEAD, which is typically what you
##'   want to do.
##'
##' @param ignore_dirty Ignore non-checked in files?  By default, your
##'   repository is expected to be in a clean state, though files not
##'   known to git are ignored (as are files that are ignored by git).
##'   But you must have no uncommited changes or staged but uncommited
##'   files.
##'
##' @param yes Skip the confirmation prompt?  Only prompts if
##'   interactive.
##' @export
release <- function(repo, version, description=NULL, filename=NULL, path=NULL,
                    metadata="datastorr.json", branch="master",
                    private=FALSE, refetch=FALSE,
                    target=NULL, ignore_dirty=FALSE,
                    yes=!interactive()) {
  info <- datastorr_info(repo, path, metadata, branch, private, refetch)
  if (is.null(filename)) {
    filename <- info$filename
    if (is.null(filename)) {
      stop("filename must be given (as is not included in json)")
    }
  }

  dat <- github_release_package_info(info, target, version)
  github_release_create_(info, dat, filename, version, description,
                         ignore_dirty, yes)
}

datastorr_info <- function(repo, path=NULL, metadata="datastorr.json",
                           branch="master", private=FALSE, refetch=FALSE) {
  if (file.exists(repo)) {
    info <- read_metadata(repo, NULL, path)
    if (private && is.null(info$private)) {
      info$private <- TRUE
    }
  } else {
    if (is.null(path)) {
      check_repo(repo)
      path <- datastorr_path(repo)
    }
    ## TODO: in the case of non-NULL path, consider stuffing the
    ## metadata into the storr above (so that things are self
    ## contained) but into a different namespace (e.g. metadata).
    ##
    ## TODO: add support for a options() path for storing file at.
    cache <- storr::storr_rds(path, default_namespace="datastorr")
    if (cache$exists("info") && !refetch) {
      info <- cache$get("info")
    } else {
      url <- sprintf("https://raw.githubusercontent.com/%s/%s/%s",
                     repo, branch, metadata)
      tmp <- download_file(url, datastorr_auth(private))
      on.exit(file.remove(tmp))
      info <- read_metadata(tmp, repo, path)
      cache$set("info", info)
    }
  }
  info
}

read_metadata <- function(filename, repo=NULL, path=NULL) {
  req <- c("read")
  valid <- union(req, c("repo", "filename", "private", "args"))

  info <- jsonlite::fromJSON(filename)
  err <- setdiff(req, names(info))
  if (length(err) > 0L) {
    stop("Missing required files in metadata file: ", paste(err, collapse=", "))
  }
  err <- setdiff(names(info), valid)
  if (length(err) > 0L) {
    stop("Unexpected data in metadata file: ", paste(err, collapse=", "))
  }

  if (is.null(info$repo)) {
    if (is.null(repo)) {
      stop("repo must be supplied if not present in metadata")
    }
    info$repo <- repo
  }

  if (is.null(info$private)) {
    info$private <- FALSE
  } else {
    p <- info$private
    if (!(length(p) == 1L && is.logical(p) && !is.na(p))) {
      stop("Expected non-NA scalar logical for private")
    }
  }

  ## So this is fundamentally dangerous because it evaluates code
  ## straight from the internet.  Worth thinking about!
  expr <- parse(text=info$read, keep.source=FALSE)
  fn_def <- function(x) {
    is.name(x) || (
      is.recursive(x) && (
        identical(x[[1L]], quote(`function`)) ||
        identical(x[[1L]], quote(`::`))))
  }
  ok <- length(expr) == 1L && fn_def(expr[[1L]])
  if (!ok) {
    stop("`read` must be a function definition or symbol")
  }
  read <- eval(expr, envir=.GlobalEnv)

  ## The other way of doing this is to store:
  ##
  ##   "read": "function(x) read.csv(x, stringsAsFactors=TRUE)"
  ##
  ## which evaluates to a function iwith all the right bits bound.
  if ("args" %in% names(info)) {
    read_fun <- read
    args <- info$args
    read <- function(x) do.call(read, c(list(x), args))
  }

  github_release_info(info$repo, read, info$private,
                      info$filename, path)
}

check_repo <- function(repo) {
  if (length(repo) != 1L) {
    stop("Expected a scalar for 'repo'")
  }
  x <- strsplit(repo, "/", fixed=TRUE)[[1L]]
  if (length(x) != 2L) {
    stop("Expected a string of form <username>/<repo> for 'repo'")
  }
}

##' Location of datastorr files.  This is determined by
##' \code{rappdirs} using the \code{user_data_dir} function.
##' Alternatively, if the option \code{datastorr.path} is set, that is
##' used for the base path.  The path to data from an actual repo is
##' stored in a subdirectory under this directory.
##'
##' Files in this directory can be deleted at will (e.g., running
##' \code{unlink(datastorr_path(), recursive=TRUE)} will delete all
##' files that datstorr has ever downloaded.  The only issue here is
##' that the OAuth token (used to authenticate with GitHub) is also
##' stored in this directory.
##'
##' @title Location of datastorr files
##'
##' @param repo An optional repo (of the form \code{user/repo}, though
##'   this is not checked).
##'
##' @export
datastorr_path <- function(repo=NULL) {
  path <- getOption("datastorr.path", rappdirs::user_data_dir("datastorr"))
  if (is.null(repo)) path else  file.path(path, repo)
}
