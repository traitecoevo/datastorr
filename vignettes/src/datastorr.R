## ---
## title: "datastorr"
## author: "Rich FitzJohn"
## date: "`r Sys.Date()`"
## output: rmarkdown::html_vignette
## vignette: >
##   %\VignetteIndexEntry{datastorr}
##   %\VignetteEngine{knitr::rmarkdown}
##   %\VignetteEncoding{UTF-8}
## ---

## ## Scope

## This package attempts to simultaneously solve a number of problems
## around small-scale data versioning and distribution:
##
## * Giving users access to your data in an easily machine-digestable
##   format.
##
## * Hosting and distributing the data somewhere fast and reliable
##   without having to deal with creating websites.
##
## * Protecting access to the data to collaborators, especially with
##   the idea of later public release.
##
## * Allowing a dataset to be downloaded once and reused for multiple
##   projects on a single computer, without having to deal with
##   pathnames within or between systems.
##
## * Versioning the data so that:
##     * fetching the current version is easy,
##     * fetching a previous version is easy,
##     * simultaneously looking at two versions is easy,
##     * data versions are strongly associated with the code that created them,
##     * end users do not have to use git,
##     * large files do not end up clogging up your git repository.
##
## * Allows publication of data packages on CRAN without causing
##   problems of large package file downloads.
##
## * Provides a common interface for storing and retrieving data that
##   works across diverse underlying data formats (one or many csv
##   files, binary data, phylogenic trees, or a collection of all of
##   these), so long as you have a way of reading the data into R.
##
## The package is designed so that you can do all of that with under
## 20 lines of code (which you can generate with one function call).

## Data comes in all shapes and sizes, and a one-size fits all
## solution will not fit everything.

## * Too small: One-off data sets (e.g. a field experient that will
##   not be updated).  Put the data on data dryad, figshare, or
##   wherever you fancy.  Stick a fork in it, it's done (though you
##   can use this package you'll likely find it easier not to).
##
## * Too big: Massively collaborative datasets with large end users
##   communities, data sets that are so large they require access via
##   APIs, data with access control requiring complex authentication
##   layers, data with complex metadata where access is related to
##   metadata.  There are more comprehensive solutions for your data
##   but identifying the correct solution may depend on the data.
##
## * Just right: A data set of medium size (say, under 100 MB), that
##   is under moderate levels of change (either stabilising or a
##   "living database" that is continually being updated).

## ## How it works

## We create an extremely small R package in a git repository, and
## publish that git repository to GitHub.  The git repository contains
## only a bit of metadata that uses `datastorr` to download and
## retrieve your data (see below).  It can however contain whatever
## code you would like for working with your data set.  In our own
## use, the repository (but not the package) contains code for
## _building_ the data set (see
## [taxonlookup](https://github.com/traitecoevo/taxonlookup)).

## GitHub has a "releases" feature for allowing (potentially large)
## file uploads.  These files can be any format.  GitHub releases are
## build off of git "tags"; they are *associated with a specific
## version*.  So if you have code that creates or processes a dataset,
## the dataset will be stored against the code used to create it,
## which is nice.  GitHub releases *do not store the file in the
## repository*.  This avoids issues with git slowing down on large
## files, on lengthy clone times, and on distributing and installing
## your package.  This could be an issue if you had 100 versions of a
## 10 MB dataset; that could be 1GB of data to clone or install.  But
## storing your data against GitHub releases will leave the data in
## the cloud until it is needed.

## The releases will be numbered.  We recommend [semantic
## versioning](http://semver.org) mostly because it signals some
## intent about changes to the data (see below).

## We will make the simplifying assumption that your data set will be
## stored in a single file.  In practice this is not a limitation
## because that file could be a zip archive.  The file can be in any
## format; csv, rds (R's internal format), a SQLite database.  You,
## however, need to provide a function that will read the data and
## convert it into an R object.  So for a csv file you'd provide a
## function that would be `read.csv` perhaps with a few arguments set
## (e.g., `stringsAsFactors=FALSE`).  For an rds file you could just
## use `readRDS`.  And for a zip file you would need a more
## complicated function (see the worked example).

## Once your git repsitory is published and your data have been
## released, downloading it becomes a function within your package.  A
## user would run something like:
##
## ```{r,eval=FALSE}
## d <- mypackage::mydata()
## ```
##
## to fetch or load the data.  This function is designed to be *fast*.
## It uses [`storr`](https://github.com/richfitz/storr) behind the
## scenes and looks in various places for the data:
##
## 1. In memory; if it has been loaded within this session it is
## already in memory.  Takes on the order of microseconds.
##
## 2. From disk; if the data has _ever_ been loaded datastorr will
## cache a copy on disk.  Takes on the order of milliseconds up to a
## second, depending on the size of the data.
##
## 3. From GitHub; if the data has never been loaded, it will be
## downloaded from GitHub, saved to disk, and loaded to memory.  This
## will take several seconds or longer depending on the size of the
## dataset.

## In addition, users can download specific versions of a dataset.
## This might be to synchronise data versions across different people
## in a project, to lock a project onto a specific version, etc:
##
## ```{r,eval=FALSE}
## d <- mypackage::mydata("v1.0.0")
## ```
##
## The same cascading lookup as above works.

## This approach extends to holding multiple versions of the data on a
## single computer (or in a single R session).  This might be useful
## when the dataset has changed and you want to see what has changed.
##
## ```{r,eval=FALSE}
## d1 <- mypackage::mydata("v1.0.0")
## d2 <- mypackage::mydata("v1.1.0")
## ## ...compare d1 and d2 here...
## ```

## ## Worked example

### TODO: I should get a link to a cooking show and do a "Here's one I
### prepared earlier" thing.

## First, you will need a package.  Creating packages is not that
## hard, especialy with tools like
## [devtools](https://github.com/hadley/devtools) and
## [mason](https://github.com/gaborcsardi/mason).  Packages make
## running R code on other machines much simpler than sourcing in
## files or copy and paste.  Packages are also nice because if your
## data require specific package to work with (e.g., `ape` for
## phylogenetic trees) you can declare them in your `DESCRIPTION` file
## and R will ensure that they are installed when your package is
## installed and loaded when your package is used.
##
## However, you will need to come up with a few details:
##
## * a package name
## * a name for the dataset (if different to the package name)
## * a _licence_ for your package (code) and data (not code)
## * ideally, documentation for your end users
## * the name of the file that you will store with each release

## In addition you need to set up a GitHub token so that you can
## upload files to GitHub from R, or to access your private
## repositories.  This is like a password so that GitHib knows it is
## you.  But it is also like a password in that if someone else gets
## it they can doo all sorts of things to your account.  So treat it
## safely!  Saving your token into your `~/.Rprofile` file seems the
## best approach because you're unlikely ever to commit it somewhere
## accidently.

## The function
##
## ```{r, eval=FALSE}
## setup_github_token()
## ```
##
## will guide you through the steps or confirm that you are set up
## correctly.

### TODO: I need to set in structions for doing that; I have them on
### my work computer but not here.  See also hadley's "best practices"
### document which has good details in it.

## To make the release:

## 1. Increase the version number in your `DESCRIPTION` file
##
## 2. Your local repo is all committed (no unstaged files etc).  This
## is important if you want to closely associate the release and your
## data and at the moment datastorr enforces it.
##
## 3. Push your changes to GitHub and install your package
##
## 4. Run `yourpackage::yourdata_release("A description here")`
##
## 5. Check that it all worked by running `yourpackage::yourdata("new version")`
##
## (you can get your new version by `read.dcf("DESCRIPTION")[,
## "Version"]`).

## ## Access control

## Because GitHub offers private repositories, this gives some
## primitive, but potentailly useful, access control.  Because
## datastorr uses GitHub's authentication, GitHub knows if the user
## has access to private repositories.  Therefore for this to work you
## will need to authenticate datastorr to work with GitHub.

## The simplest way to do this is to let datastorr prompt you when
## access is required.  Or run:
##
## ```r
## datastorr::datastorr_auth()
## ```
##
## to force the authentication process to run (no error and no output
## indicates success).  To force using personal access tokens rather
## than OAuth, run:
##
## ```r
## setup_github_token()
## ```
##
## which will walk you through the steps of setting a token up.

## If you use a personal private repository, then you invite other
## users to "collaborate" on the repository.  Note that this gives the
## users push access to the repository; the access control is very
## coarse.
##
## If you have an organisation account you can create groups of users
## that have read only access to particular repositories, which will
## likely scale better.

## ## Semantic versioning of data

## Some will argue that it is not possible and they are probably
## right.  But you need to go with some versioning system.  If the
## idea of semantically versioning data bothers you, use incrementing
## integers (`v1`, `v2`, `v<n>`) and read no further!

## The idea with semantic versioning is that it formalises what people
## do already with versioning.  We feel this can be applied fairly
## successfully to data.

## * **Update patch release**; small changes, backward compatible.
##     * adding new rows to the data set (more data)
##     * error correcting existing data

## * **Update minor version**; medium changes, but generally backward
##   compatible.
##     * new columns
##     * substantial new data
##     * new tables
##
## * **Update major version**; large (API) changes, likely to be backward
##   incompatible.
##     * renaming or deleting columns
##     * changing variable coding
##     * deleting large amounts of data

## Forks make this a lot more complicated.  If two people are working
## in parallel how do they decide what version number to use?
## However, with our solution, the datasets are still sensibly named;
## we have:
##
##    * `user1/dataset@v1.2.3`
##    * `user2/dataset@v1.3.5`
##
## It's just not possible to know from the outside exactly what
## differs between the datasets but they are at least distinctly named
## (and you could download both of them).  When the fork is resolved
## and `user2` merges back into `user1` the two researchers can
## discuss what version number they would want to use.  Like resolving
## merge conflicts, we see this as a _social_ problem, not a
## _technological_ one and the soltuion will be social.

## ## Beyond GitHub

## Apart from the ease of use, mindshare and the explicit association
## between data and code, there is no strong reason to use GitHub
## here.  Certainly Bitbucket provides all the same functionality that
## is required to generalise our approach to work there.  And self
## hosting would work too, with more effort.  Over time we may develop
## support for alternative storage providers.

## At the same time, the fast and generally reliable webserver, the
## access controls and the nice API make it a great first place to try
## this proof of concept.

## ## How it _actually_ works

## GitHub has an API that lets you programmatically query the state of
## basically everything on GitHub, as well *create* things.  So the
## interaction with the website is straightforward; getting lists of
## releases for a repository, filenames associated with releases, etc.

## With this information, `datastorr` uses a
## [`storr_external`](https://richfitz.github.io/storr/vignettes/external.html)
## object and stores data with versions as keys.  If a version is not
## found it is downloaded (using the information from GitHub) and read
## into R using the `read` function.  A copy of this R-readable
## verison is saved to disk.

## In order to save and load data repeatedly, especially across
## different projects on the same computer, `datastorr` uses the
## `rappdirs` package to find the "Right Place" to store "application
## data".  This varies by system and is documented in the
## `?rappdirs::user_data_dir` help page.  Using this directory means
## there is little chance of accidently commiting large data sets into
## the repository (which might be a problem if storing the data in a
## subdirectory of the project).
