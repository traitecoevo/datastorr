context("github_release")

test_that("github_release", {
  read_csv <- function(...) {
    read.csv(..., stringsAsFactors=FALSE)
  }

  info <- github_release_info("wcornwell/taxonlookup", read_csv)

  path <- github_release_path(info$repo)
  exists <- file.exists(path)

  expect_is(info, "github_release_info")
  expect_is(info$path, "character")
  expect_identical(info$path, path)
  expect_identical(file.exists(info$path), exists)

  ## for testing use a temporary file
  path <- tempfile("datastorr_")
  on.exit(unlink(path, recursive=TRUE))
  info <- github_release_info("wcornwell/taxonlookup", read_csv, path=path)
  expect_identical(info$path, path)
  expect_false(file.exists(path))

  st <- storr_github_release(info)
  expect_true(file.exists(path))
  expect_is(st, "storr")
  expect_identical(st$list(), character(0))

  expect_identical(github_release_versions(info), character(0))

  skip_if_no_downloads()
  tmp <- github_release_versions(info, FALSE)
  expect_more_than(length(tmp), 9)

  tmp <- github_release_version_current(info)
  expect_true(numeric_version(tmp) >= numeric_version("1.0.0"))

  dat <- github_release_get(info)

  expect_is(dat, "data.frame")
  expect_identical(st$list(), tmp)
  expect_identical(github_release_versions(info), tmp)

  github_release_del(info, tmp)
  expect_identical(github_release_versions(info, TRUE),
                   character(0))
  expect_true(file.exists(path))
  github_release_del(info, NULL)
  expect_false(file.exists(path))
})

test_that("datastorr.example", {
  ## So, basically nothing here will work without the token, and as
  ## it's my repository, that's not ideal.  Happy for other solutions
  ## here.
  skip_if_no_downloads()
  skip_if_no_github_token()
  path <- tempfile("datastorr_")
  url <- "https://github.com/richfitz/datastorr.example.git"
  system2("git", c("clone", url, path))

  owd <- setwd(path)
  on.exit({
    setwd(owd)
    unlink(path, recursive=TRUE)
  })

  ## A fairly unconventional way of loading the package :)
  source("R/package.R", local=TRUE)

  info <- mydata_info(tempfile("datastorr_"))

  d <- read.csv(file.path(owd, "example.csv"), stringsAsFactors=FALSE)
  dd <- lapply(d$dataset, get, as.environment("package:datasets"))
  names(dd) <- d$dataset

  ## Temporary place to stick data:
  tmp <- tempfile("datastorr_")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive=TRUE), add=TRUE)
  tmp_data_path <- function(x) file.path(tmp, paste0(x, ".rds"))
  lapply(d$dataset, function(x)
    saveRDS(get(x, "package:datasets"), tmp_data_path(x)))
  dd <- tmp_data_path(d$dataset)

  ## Need to delete everything:
  github_api_delete_all_releases(info, yes=TRUE)

  v_master <- numeric_version(read.dcf("DESCRIPTION")[, "Version"])
  last <- numeric_version("0.0.0")

  f <- function(i) {
    sha <- d$target[[i]]
    system2("git", c("checkout", sha))
    path_data <- file.path(tmp, paste0(d$dataset[[i]], ".rds"))
    saveRDS(dd[[i]], path_data)
    github_release_create(info, d$description[[i]], path_data, sha, yes=TRUE)
  }

  for (i in seq_len(nrow(d))) {
    if (i == nrow(d)) {
      do_last <- grepl("^https", url) && v_master > last
      if (!do_last) {
        system2("git", c("checkout", "master"))
        break
      }
    }

    x <- f(i)

    expect_is(x, "list")
    curr <- numeric_version(strip_v(x$tag_name))
    expect_true(curr > last)
    if (i < nrow(d)) {
      expect_equal(curr, numeric_version(d$version[[i]]))
    } else {
      d$version[[i]] <- as.character(curr)
    }
    expect_equal(length(x$assets), 1)
    expect_equal(x$assets[[1]]$name, paste0(d$dataset[[i]], ".rds"))
    expect_equal(x$assets[[1]]$content_type, "application/octet-stream")
    expect_equal(x$body, d$description[[i]])
    expect_equal(x$target_commitish,
                 system2("git", c("rev-parse", d$target[[i]]), stdout=TRUE))

    last <- curr
  }

  ## Now, try and make a github release on top of the branch; this
  ## should not be possible because the version will not have moved on
  ## (especially if the previous version goes with master).  I don't
  ## think this should generally run for a local clone though.
  path_data <- file.path(tmp, "rock.rds")
  saveRDS(rock, path_data)
  expect_error(github_release_create(info, "should fail", path_data,
                                     target="master", yes=TRUE),
               "is not ahead of remote version")

  ## Now, pull the data down and have a look:
  j <- seq_len(nrow(d) - if (do_last) 0 else 1)

  vv <- mydata_versions(FALSE, info$path)
  expect_equal(length(vv), length(j))
  expect_equal(vv[j], d$version[j])

  for (i in j) {
    data_i <- mydata(vv[[i]], info$path)
    expect_identical(data_i, readRDS(dd[[i]]))
  }
})
