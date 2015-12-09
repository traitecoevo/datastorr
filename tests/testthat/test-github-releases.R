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
  path <- tempfile("dataverse_")
  on.exit(unlink(path, recursive=TRUE))
  info <- github_release_info("wcornwell/taxonlookup", read_csv, path=path)
  expect_identical(info$path, path)
  expect_false(file.exists(path))

  st <- storr_github_release(info)
  expect_true(file.exists(path))
  expect_is(st, "storr")
  expect_identical(st$list(), character(0))

  skip_if_no_downloads()
  expect_identical(github_release_versions(info), character(0))

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

test_that("create releases", {
  skip_if_no_downloads()
  skip_if_no_github_token()
  github_api_delete_all_releases <- function(info) {
    d <- github_api_releases(info)
    for (x in d) {
      message("deleting ", x$tag_name)
      github_api_release_delete(info, I(x$tag_name))
    }
  }

  read_csv <- function(...) {
    read.csv(..., stringsAsFactors=FALSE)
  }
  info <- github_release_info("richfitz/testing", readRDS)

  github_api_delete_all_releases(info)

  ## Now create a new release:
  version <- "v0.0.1"
  description <- "A release"
  target <- NULL
  filename <- "mtcars.rds"
  saveRDS(mtcars, filename)
  on.exit(file.remove(filename))

  x1 <- github_release_create(info, version, description, filename, yes=TRUE)
  expect_error(github_release_create(info, version, description, filename,
                                     yes=TRUE),
               "Release already exists")

  ## TODO: I think that it should be possible to use non-rds storage
  ## here but at present don't bother.
  path <- tempfile("dataverse_")
  on.exit(unlink(path, recursive=TRUE), add=TRUE)
  info$path <- path
  st <- storr_github_release(info)
  expect_identical(st$list(), character(0))

  dat <- github_release_get(info)
  expect_identical(dat, mtcars)
  expect_identical(st$list(), strip_v(version))

  version2 <- "v0.0.2"
  x2 <- github_release_create(info, version2, filename=filename, yes=TRUE)

  d <- github_api_releases(info)
  expect_equals(length(d), 2)

  x <- github_release_versions(info, FALSE)
  expect_equals(x, equals(c("0.0.1", "0.0.2")))

  github_api_delete_all_releases(info)
})
