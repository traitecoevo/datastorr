# test-new-template.R 

test_that("Multi file test", {
  library(datastorrtest)       
  read_csv <- function(...) {
    read.csv(...)
  }
  
  read_raster <- function(...) {
    raster::raster(...)
  }
  
  read_spreadsheet <- function(...) {
    readxl::read_xls(...)
  }
  
  path <- tempfile("test-cache")
  on.exit(unlink(path, recursive = TRUE))
  info <- github_release_info("FabriceSamonte/datastorrtest", 
                                    c(read_csv, read_spreadsheet), 
                                    filename=c("baad_with_map.csv", "Globcover_Legend.xls"),
                                    path=path)
  
  exists <- file.exists(path)
  
  expect_is(info, "github_release_info")
  expect_is(info$path, "character")
  expect_identical(info$path, path)
  expect_identical(file.exists(info$path), exists)
  
  # version test 
  
  expect_identical(github_release_version_current(info), "2.0.0")
  expect_identical(github_release_version_current(info, local=FALSE), "2.0.0")
  expect_identical(github_release_versions(info), character(0))
  expect_is(github_release_versions(info), "character")
  
  
  # test datastorr attributes 
  st <- R6_datastorr$new(info) 
  
  expect_identical(path, st$path)
  expect_identical(st$storr$list("file"), character(0))
  
  expect_identical(st$version_current(), "2.0.0")
  expect_identical(st$version_current(local=FALSE), "2.0.0")
  expect_identical(st$versions(), character(0))
  expect_is(st$versions(local=FALSE), "character")
  
  dat <- st$get(version="2.0.0")
  
  expect_is(dat, "list")
  
  expect_identical(st$version_current(), "2.0.0")
  expect_identical(st$versions(), "2.0.0")
  expect_is(st$storr$list("file"), "character")
  expect_silent(st$del("2.0.0"))
  expect_error(st$del("2.0.0"))
  
  st$del(NULL)
  expect_true(!file.exists(path))
  
  
  
})