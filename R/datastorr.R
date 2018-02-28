## This is the core of the package - it holds all the facilities for
## caching etc.
R6_datastorr <- R6::R6Class(
  "datastorr",
  public = list(
    storr = NULL,
    cache = NULL,
    info = NULL,
    path = NULL,

    initialize = function(info) {
      self$info <- info
      self$path <- info$path
      self$storr <- storr::storr_rds(self$path)
      self$cache <- storr::storr_environment()

      dir.create(file.path(self$path, "file"), FALSE, TRUE)
      dir.create(file.path(self$path, "workdir"), FALSE, TRUE)

      lockBinding("info", self)
      lockBinding("path", self)
    },

    get = function(version = NULL, download = TRUE, verbose = TRUE,
                   reread = FALSE) {
      if (is.null(version)) {
        version <- self$version_current()
      }
      if (!self$storr$exists(version, "file") && download) {
        self$download(version, verbose)
      }
      self$read(version, reread)
    },

    read = function(version, reread = FALSE) {
      if (reread || !self$cache$exists(version)) {
        file <- file.path(self$path, "file", self$storr$get(version, "file"))
        ret <- self$info$read(file)
        self$cache$set(version, ret, use_cache = FALSE)
      } else {
        ret <- self$cache$get(version, use_cache = FALSE)
      }
      ret
    },

    download = function(version, verbose = TRUE) {
      url <- github_api_release_url(version, self$info$filename, self$info$repo,
                                    self$info$private)

      filename <- basename(sub("\\?.*$", "", url))
      ext <- tools::file_ext(filename)
      if (!nzchar(ext)) {
        ext <- paste0(".", ext)
      }

      tmp <- tempfile(tmpdir = file.path(self$path, "workdir"), fileext = ext)
      on.exit(unlink(tmp))
      download_file(url, dest = tmp, verbose = verbose, binary = TRUE)

      hash <- unname(tools::md5sum(tmp))
      file <- paste0(hash, ext)
      dest <- file.path(self$path, "file", file)
      if (!file.exists(dest)) {
        file.rename(tmp, dest)
      }
      self$storr$set(version, hash, "hash")
      self$storr$set(version, file, "file")
    },

    versions = function(local = TRUE) {
      if (local) {
        self$storr$list("file")
      } else {
        rev(names(github_api_cache(self$info$private)$get(self$info$repo)))
      }
    },

    version_current=function(local = TRUE) {
      v <- self$versions(local)
      if (length(v) == 0L && local) {
        v <- self$versions(FALSE)
      }
      if (length(v) == 0L) {
        NULL
      } else {
        v[[length(v)]]
      }
    },

    del = function(version) {
      if (is.null(version)) {
        unlink(file.path(self$path, "file"), recursive = TRUE)
        self$storr$destroy()
      } else {
        file <- self$get(version)
        unlink(file.path(self$path, "file", file))
        self$del(version, "file")
        self$del(version, "hash")
        self$del(version)
      }
    }
  ))
