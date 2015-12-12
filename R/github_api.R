## Github API helpers.  There's a chance that some of this will port
## to use the gh package once it's on CRAN.

cache <- new.env(parent=emptyenv())
github_api_cache <- function(private) {
  fetch <- function(key, namespace) {
    ret <- github_api_releases(list(repo=key, private=private))
    tag_names <- vcapply(ret, "[[", "tag_name")
    names(ret) <- strip_v(tag_names)
    i <- duplicated(names(ret))
    if (any(i)) {
      warning("Removing duplicated tag names: ",
              paste(sprintf("%s (%s)", names(ret)[i], tag_names[i]),
                    collapse=", "))
      ret <- ret[!i]
    }
    ret
  }
  force(private)
  storr::storr_external(storr::driver_environment(cache), fetch)
}

github_api_cache_clear <- function(info) {
  github_api_cache(info$private)$del(info$repo)
}

## Token for accessing private repos, and for creating releases.
github_api_token <- function(required=FALSE) {
  token <- Sys.getenv("GITHUB_TOKEN", "")
  if (token == "") {
    if (required) {
      stop("GitHub token not found; please set GITHUB_TOKEN environment variable")
    } else {
      return(NULL)
    }
  }
  httr::authenticate(token, "x-oauth-basic", "basic")
}

github_api_release_info <- function(info, version) {
  st <- github_api_cache(info$private)
  vv <- strip_v(version)
  x <- st$get(info$repo)

  if (vv %in% names(x)) {
    ret <- x[[vv]]
  } else {
    url <- sprintf("https://api.github.com/repos/%s/releases/tags/%s",
                   info$repo, add_v(version))
    r <- httr::GET(url, github_api_token(info$private))
    if (httr::status_code(r) >= 300L) {
      msg <- httr::content(r)$message
      if (is.null(msg)){
        msg <- "(no message)"
      }
      stop(sprintf("No such release with error: %d, %s",
                   httr::status_code(r), msg))
    }
    ## Invalidate the cache as we're clearly out of date:
    github_api_cache_clear(info)
    ret <- httr::content(r)
  }
  ret
}

github_api_releases <- function(info) {
  ## TODO: This will be more nicely handled with the pagnation
  ## feature of Gabor's gh package but I'd rather that hits CRAN
  ## before depending on it.  Replace the following four lines with:
  ##   ret <- gh::gh("/repos/:repo/releases", repo=key)
  url <- sprintf("https://api.github.com/repos/%s/releases", info$repo)
  dat <- httr::GET(url,
                   query=list(per_page=100),
                   github_api_token(info$private))
  httr::stop_for_status(dat)
  httr::content(dat)
}

github_api_release_delete <- function(info, version, yes=FALSE) {
  message(sprintf("Deleting version %s from %s", version, info$repo))
  if (!yes && !prompt_confirm()) {
    stop("Not deleting release")
  }
  x <- github_api_release_info(info, version)

  r <- httr::DELETE(x$url, github_api_token(TRUE))
  httr::stop_for_status(r)
  github_api_cache_clear(info)
  ## Need to also delete the tag:
  github_api_tag_delete(info, x$tag_name)
  invisible(TRUE)
}

github_api_tag_delete <- function(info, tag_name) {
  url <- sprintf("https://api.github.com/repos/%s/git/refs/tags/%s",
                 info$repo, tag_name)
  r <- httr::DELETE(url, github_api_token(TRUE))
  httr::stop_for_status(r)
  invisible(httr::content(r))
}

github_api_release_create <- function(info, version,
                                      description=NULL, target=NULL) {
  data <- list(tag_name=add_v(version),
               body=description,
               target_commitish=target)
  url <- sprintf("https://api.github.com/repos/%s/releases", info$repo)
  r <- httr::POST(url, body=drop_null(data), encode="json",
                  github_api_token(TRUE))
  github_api_catch_error(r, "Failed to create release")
  github_api_cache_clear(info)
  invisible(httr::content(r))
}

github_api_release_upload <- function(info, version, filename, name) {
  x <- github_api_release_info(info, version)
  r <- httr::POST(sub("\\{.+$", "", x$upload_url),
                  query=list(name=name),
                  body=httr::upload_file(filename),
                  httr::progress("up"),
                  github_api_token(TRUE))
  cat("\n") # clean up after httr's progress bar :(
  httr::stop_for_status(r)
  github_api_cache_clear(info)
  invisible(httr::content(r))
}

github_api_release_update <- function(info, version,
                                      description=NULL, target=NULL) {
  x <- github_api_release_info(info, version)
  data <- list(tag_name=version,
               body=description,
               target_commitish=target)
  r <- httr::PATCH(x$url, body=drop_null(data),
                   github_api_token(TRUE), encode="json")
  httr::stop_for_status(r)
  github_api_cache_clear(info)
  invisible(httr::content(r))
}

github_api_repo <- function(info) {
  url <- sprintf("https://api.github.com/repos/%s", info$repo)
  r <- httr::GET(url, github_api_token(info$private))
  httr::stop_for_status(r)
  httr::content(r)
}
github_api_ref <- function(info, ref, type="heads") {
  type <- match.arg(type, c("heads", "tags"))
  url <- sprintf("https://api.github.com/repos/%s/git/refs/%s/%s",
                 info$repo, type, ref)
  r <- httr::GET(url, github_api_token(info$private))
  httr::stop_for_status(r)
  httr::content(r)
}

github_api_commit <- function(info, sha) {
  url <- sprintf("https://api.github.com/repos/%s/git/commits/%s",
                 info$repo, sha)
  r <- httr::GET(url, github_api_token(info$private))
  github_api_catch_error(r)
  httr::content(r)
}

github_api_catch_error <- function(r, message=NULL) {
  code <- httr::status_code(r)
  if (code > 300L) {
    x <- httr::content(r)
    if (code == 422L) {
      e <- x$errors[[1]]
      msg <- paste(e$resource, sub("_", " ", e$code))
      if (!is.null(x$message)) {
        msg <- sprintf("%s (%s)", msg, x$message)
      }
    } else {
      msg <- httr::http_status(r)$message
    }
    if (!is.null(message)) {
      msg <- sprintf("%s: %s", message, msg)
    }
    stop(msg, call.=FALSE)
  }
}

## Consistently deal with leading vs; we'll just remove them
## everywhere that has them and that way vx.y.z will match x.y.z and
## v.v.  Pretty strict matching though.
strip_v <- function(x) {
  if (inherits(x, "AsIs")) {
    x
  } else {
    sub("^v([0-9]+([-_.][0-9]+){0,2})", "\\1", x)
  }
}
add_v <- function(x) {
  if (!inherits(x, "AsIs")) {
    i <- grepl("^([0-9]+([-_.][0-9]+){0,2})$", x)
    x[i] <- paste0("v", x[i])
  }
  x
}

drop_null <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}
