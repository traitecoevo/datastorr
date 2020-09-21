## test-data-package.R 

test_that("datastorrtest", {
  ## if this doesn't work, run: 
  ## devtools::install_github("FabriceSamonte/datastorrtest)
  ## 
  library(datastorrtest)
  
  path <- tempfile("test-cache")
  on.exit(unlink(path, recursive = TRUE))
  
  expect_is(dataset_access_function(version="2.0.0", path=path), "list")
  expect_is(dataset_access_function(version="1.0.0", path=path), "data.frame")
  
  expect_identical(dataset_versions(local=TRUE, path=path), c("1.0.0", "2.0.0"))
  
  expect_silent(datastorrtest::dataset_del("1.0.0", path=path))
  expect_silent(datastorrtest::dataset_del("2.0.0", path=path))
  
  # can't delete something that doesn't exist
  expect_error(datastorrtest::dataset_del("2.0.0", path=path))
  
  expect_identical(dataset_versions(local=TRUE, path=path), character(0))
  
})

test_that("taxonlookup", {
  
  library(taxonlookup)
  
  path <- tempfile("test-cache")
  on.exit(unlink(path, recursive = TRUE))
  
  expect_is(plant_lookup(path=path), "data.frame")
  expect_silent(plant_lookup_del(version=NULL))

})  

  
  
