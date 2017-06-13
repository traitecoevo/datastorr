##' Autogenerate an datastorr interface for a package.  The idea is to
##' run this function and save the resulting code in a file in your
##' package.  Then users will be able to download data and you will be
##' able to relase data easily.
##'
##' In addition to running this, you will need to add \code{datastorr}
##' to the \code{Imports:} section of your DESCRIPTION.  To upload
##' files you will need to set your \code{GITHUB_TOKEN} environment
##' variable.  These steps will be described more fully in a vignette.
##'
##' More complete instructions:
##'
##' Let \code{pkg} be \code{basename(repo}); the name of the package
##' and of the GitHub repository.
##'
##' First, create a new R package, e.g.  \code{devtools::create(pkg)}.
##'
##' Then, copy the result of running \code{autogenerate} into a file
##' in that package, e.g.
##'
##' \preformatted{   writeLines(autogenerate(repo, read),
##'              file.path(pkg, "datastorr.R"))
##'   devtools::document(pkg)
##' }
##'
##' Create a new git repository for this package, and add all the
##' files in the package, and commit.
##'
##' On GitHub, create a repository for the package and push your code
##' there.
##'
##' At this point you are now ready to start making releases by
##' loading your package and running \code{pkg::<name>_release()}.
##'
##' @title Autogenerate a datastorr interface
##'
##' @param repo Name of the repo on github (in username/repo format)
##'
##' @param read \emph{name} of a function to read the data.  Do not
##'   give the function itself!
##'
##' @param filename Name of the file to read.  If not given, then the
##'   single file in a release will be read (but you will need to
##'   provide a filename on upload).  If given, you cannot change the
##'   filename ever as all releases will be assumed to have the same
##'   filename.
##'
##' @param name Name of the dataset, used in generating the functions.
##'   If omitted the repo name is used.
##'
##' @param roxygen Include roxygen headers for the functions?
##'
##' @export
##' @examples
##' writeLines(autogenerate("richfitz/datastorr.example",
##'                         read="readRDS", name="mydata"))
##' writeLines(autogenerate("richfitz/datastorr.example",
##'                         read="readRDS", name="mydata",
##'                         roxygen=FALSE))
autogenerate <- function(repo, read, filename=NULL, name=basename(repo),
                         roxygen=TRUE) {
  loadNamespace("whisker")
  template <- readLines(system.file("template.whisker", package=.packageName))
  if (is.null(filename)) {
    filename <- "NULL"
  } else {
    filename <- sprintf('"%s"', filename)
  }
  if (!is.character(read)) {
    stop("Expected a string for the function")
  }
  data <- list(repo=repo, read=read, name=name, filename=filename)
  x <- whisker::whisker.render(template, data)
  x <- strsplit(x, "\n")[[1]]
  if (!roxygen) {
    x <- x[!grepl("^##'", x)]
  }
  ## Part of a workaround around a whisker bug:
  x <- gsub("{ ", "{", x, fixed=TRUE)
  x <- gsub(" }", "}", x, fixed=TRUE)
  if (is.null(filename)) {
    cat(x, sep = "\n")
  } else {
    x
  }
}
