context("simple")

test_that("basic usage", {
  d <- read.csv("example.csv", stringsAsFactors=FALSE)
  dd_contents <- lapply(d$dataset, get, as.environment("package:datasets"))
  names(dd_contents) <- d$version
  len <- length(dd_contents)

  path <- tempfile()
  d <- datastorr("richfitz/datastorr.example", path=path)

  expect_equal(d, dd_contents[[length(dd_contents)]])

  obj <- datastorr("richfitz/datastorr.example", path=path, extended=TRUE)
  v <- obj$versions(FALSE)
  expect_equal(length(v), len)
  expect_equal(v[-len], names(dd_contents)[-len])
  names(dd_contents) <- v

  for (i in v) {
    expect_equal(obj$get(i), dd_contents[[i]])
  }

  expect_equal(obj$versions(), v)

  expect_equal(obj$path, path)

  expect_equal(obj$version_current(), v[[len]])
  expect_equal(obj$version_current(FALSE), v[[len]])
  obj$del(NULL)
  expect_false(file.exists(path))
})
