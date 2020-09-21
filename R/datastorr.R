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
      
      # DEFAULT should pull the source code 
      # TODO: temporary solution is to fill in NULL fileanmes 
      # with "version.zip" and handle it at 
      # download stage 
      if (is.null(self$info$filenames)) {
        filenames <- "Source.zip"
      } else {
        filenames <- self$info$filenames
      }
      
      for(target_file in filenames) {
        version_file <- create_version_filename(version, target_file)  
        if (!self$storr$exists(version_file, "file") && download) {
         self$download(version, target_file, verbose)
        }
      }
      
      ## TODO: messy handling of single vs multiple files 
      if(length(filenames) == 1L) {
        self$read(version, filenames[1], self$info$read[[1]], reread)
      } else { 
        opened_files <- vector("list", length=length(filenames))
        for(index in 1:length(opened_files)) {
          opened_files[[index]] <- self$read(version, filenames[index], self$info$read[[index]], reread)
        }
        names(opened_files) <- filenames
        opened_files
      }
    },

    read = function(version, target_file, read_function, reread = FALSE) {
      version_file <- create_version_filename(version, target_file)
      if (reread || !self$cache$exists(version_file)) {
        file <- file.path(self$path, "file", self$storr$get(version_file, "file"))
        ret <- read_function(file)
        self$cache$set(version_file, ret, use_cache = FALSE)
      } else {
        ret <- self$cache$get(version_file, use_cache = FALSE)
      }
      ret
    },

    download = function(version, target_file, verbose = TRUE) {
      # API interaction 
      message(paste0("Downloading ", target_file))
      
      # This check needs to be changed 
      # to enable backwards compatibilty 
      if(target_file == "Source.zip") {  
        url <- github_api_source_url(version, self$info$repo, self$info$private)
        filename <- "Source.zip"
      } else {
        url <- github_api_release_url(version, target_file, self$info$repo,
                                      self$info$private)
        filename <- basename(sub("\\?.*$", "", url)) 
      }  
      
      ## needs new handling when source code is being pulled
      ext <- tools::file_ext(filename)
      if (nzchar(ext)) {
        ext <- paste0(".", ext)
      }
      
      tmp <- tempfile(tmpdir = file.path(self$path, "workdir"), fileext = ext)
      on.exit(unlink(tmp))
      download_file(url, dest = tmp, verbose = verbose, binary = ifelse(target_file == "Source.zip", FALSE, TRUE))
      
      # hash key for storr  
      hash <- unname(tools::md5sum(tmp))
      # file name 
      file <- paste0(hash, ext)
      dest <- file.path(self$path, "file", file)
      if (!file.exists(dest)) {
        file.rename(tmp, dest)
      }
      
      version_filename <- create_version_filename(version, target_file)
      self$storr$set(version_filename, hash, "hash")
      self$storr$set(version_filename, file, "file")
      
    },

    versions = function(local = TRUE) {
      if (local) {
        local_files <- self$storr$list("file")
        local_versions <- unlist(lapply(local_files, function(x) {regmatches(x,regexpr("^(\\d+\\.){2}\\d+(?:(\\.\\d+))?",x))}))
        # Captures versions formatted x.y.z with optional 4th sub version
        stringr::str_sort(unique(local_versions), numeric=TRUE)
      } else {
        rev(names(github_api_cache(self$info$private)$get(self$info$repo)))
      }
    },

    version_current = function(local = TRUE) {
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
        # delete all files cached with associated repository 
        unlink(file.path(self$path, "file"), recursive = TRUE)
        self$storr$destroy()
      } else {
        # delete all files from specified version
        file_list_keys <- self$storr$list("file")[grepl(get_version_regex(version), self$storr$list("file"))]
        if(length(file_list_keys) == 0L) {
          stop(paste0("Version ", version, " is already deleted or does not exist"))
        }
        for(key in file_list_keys) {
          file <- self$storr$get(key, "file")
          unlink(file.path(self$path, "file", file))
          self$storr$del(key, "file")
          self$storr$del(key, "hash")
          self$cache$del(key)
        }
      }
    }
  )
)
