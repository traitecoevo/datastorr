##' Authentication for accessing GitHub.  This will first look for a
##' GitHub personal token (stored in the \code{GITHUB_TOKEN} or
##' \code{GITHUB_PAT} environment variables, and then try
##' authenticating with OAuth.
##'
##' Run this \code{datastorr_auth} function to force setting up
##' authentication with OAuth.  Alternatively, run
##' \code{setup_github_token} to set up a personal access token.
##' Either can be revoked at any time
##' \url{https://github.com/settings/tokens} to revke a personal
##' access token and \url{https://github.com/settings/applications} to
##' revoke the OAuth token.
##'
##' @title datastorr/GitHub authentication
##' @param required Is authentication required?  Reading from public
##'   repositories does not require authentication so there's no point
##'   worrying if we can't get it.  datastorr will set this when
##'   appropriate internally.
##' @param key,secret The application key and secret.  If \code{NULL},
##'   uses datastorr's key.  But if you have your own application feel
##'   free to replace these with your own.
##' @param cache Logical, indicating whether we should cache the
##'   token.  If \code{TRUE}, the token will be cached at
##'   \code{\link{datastorr_auth}()}, so that it is accessible to all
##'   datastorr usages.  Note that this is affected by the
##'   \code{datastorr.path} global option.  Alternatively, set
##'   \code{FALSE} to do no caching and be prompted each session or a
##'   string to choose your own filename.  Or set the
##'   \code{GITHUB_TOKEN} or \code{GITHUB_PAT} environment variables
##'   to use a token rather than OAuth.
##' @export
datastorr_auth <- function(required=FALSE, key=NULL, secret=NULL, cache=TRUE) {
  token <- github_token()
  ## Only go out to OAuth if required:
  if (required && is.null(token)) {
    token <- datastorr_oauth(key, secret, cache)
  }
  if (required && is.null(token)) {
    stop("GitHub token not found; please see ?datastorr_token")
  }
  invisible(token)
}

## NOTE: also using GITHUB_PAT because that's what devtools uses so
## might be able to piggy back of that in some cases, but starting
## with GITHUB_TOKEN because it's more self explanatory and Hadley
## also uses that in the httr "Best practices" document.
##
## My token doesn't seem to have the right scope at present so
## temporarily expandsing this a bit.
github_token <- function() {
  token <- Sys.getenv("DATASTORR_TOKEN",
                      Sys.getenv("GITHUB_TOKEN",
                                 Sys.getenv("GITHUB_PAT", "")))
  if (token == "") {
    NULL
  } else {
    httr::authenticate(token, "x-oauth-basic", "basic")
  }
}

datastorr_oauth <- function(key=NULL, secret=NULL, cache=TRUE) {
  if (is.null(key)) {
    key <- "d6da716e8eabccb6e3db"
    secret <- "4e83b024b12bb249f1052cfb1c259bd3baa5e672"
  }
  if (isTRUE(unname(cache))) {
    ## Here, we might want to consider trying both the option with and
    ## without the options for datastorr.path because if an option is
    ## set we don't want to have to redo the auth just for that
    ## application?
    cache <- file.path(datastorr_path(), "httr-oath")
    dir.create(dirname(cache), FALSE, TRUE)
  }
  endpoint <- httr::oauth_endpoints("github")
  app <- httr::oauth_app("github/datastorr", key=key, secret=secret)
  token <- httr::oauth2.0_token(endpoint, app, scope="repo", cache=cache)
  httr::config(token=token)
}

##' @export
##' @rdname datastorr_auth
##' @param path Path to environment file; the default is the user
##'   environment variable file which is usually a good choice.
setup_github_token <- function(path="~/.Renviron") {
  if (file.exists(path)) {
    dat <- readLines(path)
    if (any(grepl("^\\s*GITHUB_TOKEN\\s*=[A-Za-z0-9]+\\s*$", dat))) {
      message("Your GitHub token is set!")
      return(invisible())
    } else {
      message("Did not find GitHub token in ", path)
    }
  }

  message("In the page that will open:")
  message("  1. add a description (e.g. your computer name)")
  message("  2. click 'Generate token'")
  message("  3. copy the token or click the 'copy' button")
  message("  4. close the window and come back to R")
  if (!prompt_confirm()) {
    stop("Cancelling", call.=FALSE)
  }
  browseURL("https://github.com/settings/tokens/new")

  message("  5. paste your token in below and press return")
  token <- readline("GITHUB_TOKEN = ")
  prompt <- sprintf("Add token %s to '%s'?",
                    sub("^(...).*(...)$", "\\1...\\2", token), path)
  if (nchar(token) == 0L || !prompt_confirm(prompt)) {
    stop("Cancelling", call.=FALSE)
  }

  environ <- c("# Added by datastorr:", paste0("GITHUB_TOKEN=", token))
  if (file.exists(path)) {
    environ <- c(readLines(path), environ)
  }
  writeLines(environ, path)
  Sys.setenv(GITHUB_TOKEN=token)
}
