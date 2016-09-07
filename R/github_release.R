##' Create a github release for your package.  This tries very hard to
##' do the right thing but it's not always straightforward.  It first
##' looks for your package.  Then it will work out what your last
##' commit was (if \code{target} is NULL), the version of the package
##' (from the DESCRIPTION).  It then creates a release on GitHub with
##' the appropriate version number and uploads the file
##' \code{filename} to the release.  The version number in the
##' DESCRIPTION must be greater than the highest version number on
##' GitHub.
##'
##' This function requires a system git to be installed and on the
##' path.  The version does not have to be particularly recent.
##'
##' This function also requires the \code{GITHUB_TOKEN} environment
##' variable to be set, and for the token to be authorised to have
##' write access to your repositories.
##'
##' @title Create a github release
##'
##' @param info Result of running \code{github_release_info}
##'
##' @param description Optional text description for the release.  If
##'   this is omitted then GitHub will display the commit message from
##'   the commit that the release points at.
##'
##' @param filename Filename to upload; optional if in \code{info}.
##'   If listed in \code{info}, \code{filename} can be different but
##'   the file will be renamed to \code{info$filename} on uploading.
##'   If given but not in \code{info}, the uploaded file will be
##'   \code{basename(filename)} (i.e., the directory will be
##'   stripped).
##'
##' @param target Target of the release.  This can be either the name
##'   of a branch (e.g., \code{master}, \code{origin/master}),
##'   existing tag \emph{without a current release} or an SHA of a
##'   commit.  It is an error if the commit that this resolves to
##'   locally is not present on GitHub (e.g., if your branch is ahead
##'   of GitHub).  Push first!
##'
##' @param ignore_dirty Ignore non-checked in files?  By default, your
##'   repository is expected to be in a clean state, though files not
##'   known to git are ignored (as are files that are ignored by git).
##'   But you must have no uncommited changes or staged but uncommited
##'   files.
##'
##' @param yes Skip the confirmation prompt?  Only prompts if
##'   interactive.
##'
##' @export
github_release_create <- function(info, description=NULL,
                                  filename=NULL,
                                  target=NULL,
                                  ignore_dirty=FALSE,
                                  yes=!interactive()) {
  if (is.null(filename)) {
    if (is.null(info$filename)) {
      stop("filename must be given")
    }
    filename <- info$filename
  }
  if (!file.exists(filename)) {
    stop(sprintf("File %s not found", filename))
  }
  if (is.null(info$filename)) {
    info$filename <- basename(filename)
  } else if (grepl("/", info$filename, fixed=TRUE)) {
    stop("Expected path-less info$filename")
  }

  dat <- github_release_package_info(info, target)

  github_release_create_(info, dat, filename, version, description,
                         ignore_dirty, yes)
}

github_release_create_ <- function(info, dat, filename, version, description,
                                   ignore_dirty, yes) {
  if (!file.exists(filename)) {
    stop("Filename does not exist: ", filename)
  }
  github_release_preflight(dat, ignore_dirty)

  ## This is the complicated bit of the message; enough context to
  ## know if the message looks good.
  msg_at <- c("  at:",
              paste0("    sha: ", dat$sha_remote$sha),
              paste0("    date: ", dat$sha_remote$committer$date),
              paste0("    message: ",
                     paste(dat$sha_remote$message, collapse="\n")),
              paste0("    by: ",
                     sprintf("%s <%s>",
                     dat$sha_remote$committer$name,
                     dat$sha_remote$committer$email)))

  version <- add_v(dat$version_local)
  target <- dat$sha_local

  ftarget <- if (is.null(info$filename)) basename(filename) else info$filename

  ## TODO: will this fail in the case where info$filename is null?
  msg_file <- sprintf("  file: %s (as %s) %.2f KB", filename, ftarget,
                      file.info(filename)$size / 1024)

  message("Will create release:")
  message("  tag: ", version)
  message(paste(msg_at, collapse="\n"))
  message(msg_file)
  message("  description: ",
          if (is.null(description)) "(no description)" else description)

  if (!yes && !prompt_confirm()) {
    stop("Not creating release")
  }

  ret <- github_api_release_create(info, version, description, target)
  asset <- github_api_release_upload(info, version, filename, info$filename)
  ret$assets <- list(asset)

  message("Created release!")
  message("Please check the page to make sure everything is OK:\n",
          ret$html_url)
  if (interactive() && !yes && prompt_confirm("Open in browser?")) {
    utils::browseURL(ret$html_url)
  }
  invisible(ret)
}

github_release_package_info <- function(info, sha_local=NULL, version=NULL) {
  ## This can be done with either system commands or with git2r.  Not
  ## entirely sure which is the least bad way of doing it.
  git <- Sys.which("git")
  if (git == "") {
    stop("Need a system git to create releases: http://git-scm.com")
  }

  if (is.null(version)) {
    git_root <- system2(git, c("rev-parse", "--show-toplevel"), stdout=TRUE)
    pkg_root <- find_package_root(git_root)
    dcf <- as.list(read.dcf(file.path(pkg_root, "DESCRIPTION"))[1,])
    version_local <- dcf$Version
  } else {
    version_local <- version
  }
  version_remote <- github_release_version_current(info, FALSE)

  if (is.null(sha_local)) {
    sha_local <- system2(git, c("rev-parse", "HEAD"), stdout=TRUE)
  } else {
    err <- tempfile()
    on.exit(file.remove(err))
    res <- suppressWarnings(
      system2(git, c("rev-parse", sha_local), stdout=TRUE, stderr=err))
    code <- attr(res, "status", exact=TRUE)
    if (!is.null(code) && code != 0L) {
      stop(paste(c("Did not find sha in local git tree: ", readLines(err)),
                 collapse="\n"))
    }
    sha_local <- as.character(res)
  }
  sha_remote <- tryCatch(github_api_commit(info, sha_local),
                         error=function(e) NULL)

  status <- system2(git, c("status", "--porcelain", "--untracked-files=no"),
                    stdout=TRUE)
  dirty <- length(status) > 0L

  nversion_local <- numeric_version(version_local)
  if (is.null(version_remote)) {
    nversion_remote <- NULL
  } else {
    nversion_remote <- numeric_version(strip_v(version_remote))
  }

  list(version_local=version_local,
       version_remote=version_remote,
       nversion_local=nversion_local,
       nversion_remote=nversion_remote,
       sha_local=sha_local,
       sha_remote=sha_remote,
       status=status,
       dirty=dirty)
}

github_release_preflight <- function(dat, ignore_dirty=FALSE) {
  if (is.null(dat$sha_remote)) {
    stop(sprintf("Could not resolve sha %s on remote", dat$sha_local))
  }

  if (dat$dirty && !ignore_dirty) {
    msg <- paste(c("Local git is dirty (untracked files ignored):",
                   dat$status), collapse="\n")
    stop(msg)
  }

  if (!is.null(dat$nversion_remote) &&
       dat$nversion_remote >= dat$nversion_local) {
    stop(sprintf("Local version (%s) is not ahead of remote version (%s)",
                 dat$version_local, dat$version_remote))
  }
}
