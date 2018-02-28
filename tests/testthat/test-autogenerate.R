context("autogenerate")

test_that("basic", {
  res <- autogenerate("richfitz/datastorr.example", "readRDS", name="mydata")
  expect_is(res, "character")

  res2 <- autogenerate("richfitz/datastorr.example", "readRDS", name="mydata",
                       roxygen=FALSE)
  expect_lt(length(res2), length(res))
  expect_gt(length(res2), 0)
  expect_true(all(res2 %in% res))

  skip_if_no_downloads()
  path <- tempfile()
  download_file("https://raw.githubusercontent.com/richfitz/datastorr.example/master/R/package.R", dest=path)
  cmp <- readLines(path)
  expect_equal(res, cmp)
})
