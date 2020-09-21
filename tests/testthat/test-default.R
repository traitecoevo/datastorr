# test-default.R 

test_that("Default Case", {
  
  unpack <- function(...) {
    files <- unzip(...) 
  }
  
  path <- tempfile("test-cache")
  on.exit(unlink(path, recursive = TRUE))
  info <- github_release_info("FabriceSamonte/datastorrtest", 
                              c(length), 
                              filename=NULL,
                              path=path)
  
  exists <- file.exists(path)
  
  st <- R6_datastorr$new(info) 
  
  expect_identical(path, st$path)
  expect_identical(st$storr$list("file"), character(0))
  
  dat <- st$get() 
  
  
  info <- github_release_info("FabriceSamonte/datastorrtest", 
                              read=unpack, 
                              filename="Source.zip",
                              path=path)
  
  st <- R6_datastorr$new(info) 
  
  expect_identical(github_release_version_current(info), "2.0.0")
  expect_identical(github_release_version_current(info, local=FALSE), "2.0.0")
  expect_identical(github_release_versions(info), "2.0.0")
  expect_is(github_release_versions(info), "character")
  
  dat <- st$get()  
  
  
  
}
)