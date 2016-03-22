# datastorr

Simple data retrieval and versioning using GitHub to store data.

**Warning: the functions in here are subject to rationalisation over the next little bit, especially as I harmonise the interfaces**

## The problem

There are a number of related problems that `datastorr` tries to address.  Mostly these fall into the category of:

* You are working on an analysis that requires data that don't easily fit in GitHub
* You need to distribute datafiles to people to use, but the data changes periodically

The obvious solution to this is "put the files up online somewhere and download them when you need them".  This is what `datastorr` does.  But in doing so it tries to solve the auxillary problems:

* Caching the downloads, including across R sessions, to make things faster and to work offline
* Deal consistently with translating the file stored online into a loaded data object
* Keep track of which versions are downloaded and available remotely
* Allows you to access multiple versions of the data at once (helpful if working out why results have changed)

## How datastorr helps

This package can be used in two ways:

1. Use data stored elsewhere in R efficiently (e.g. work with csv files that are too large to comfortably fit in git).
2. Create another lightweight package designed to allow easy access to your data.

For both of these use-cases, `datastorr` will store your data using _GitHub releases_ which do not clog up your repository but allow up to 2GB files to be stored (future versions may support things like figshare).

`datastorr` is concerned about a simple versioning scheme for your data.  If you do not imagine the version changing that should not matter.  But if you work with data that changes (and everyone does eventually) this approach should make it easy to update files.

From the point of view of a user, using your data could be as simple as:

```r
d <- datastorr::datastorr("richfitz/datastorr.example")
```

(see below for details, how this works, and what it is doing).

## End user interface

See [here](https://github.com/richfitz/datastorr.example) for the aim from the point of view for an end user.

They would install your package (which contains no data so is nice and
light and can be uploaded to CRAN).

```r
devtools::install_github("richfitz/datastorr.example")
```

The user can see what versions they have locally

```r
datastorr.example::mydata_versions()
```

and can see what versions are present on github:

```r
datastorr.example::mydata_versions(local=FALSE) # remote
```

To download the most recent dataset:

```r
d <- datastorr.example::mydata()
```

Subsequent calls (even across R sessions) are cached so that the mydata() function is fast enough you can use it in place of the data.

To get a particular version:

```r
d <- datastorr.example::mydata("0.0.1")
```

Downloads are cached across sessions using `rappdirs`.

## Package developer process

The simplest way is to run the (hidden) function `datastorr:::autogenerate`, as


```r
datastorr:::autogenerate(repo="richfitz/datastorr.example", read="readRDS", name="mydata")
```

which will print to the screen a bunch of code to add do your package.  There will be a vignette explaining this more fully soon.  A file generated in this way can be seen  [here](https://github.com/richfitz/datastorr.example/blob/master/R/package.R).

Once set up, new releases can be made by running, within your package directory:

```r
datastorr.example::mydata_release("description of release", "path/to/file")
```

provided you have your `GITHUB_TOKEN` environment variable set appropriatey.  See the vignette for more details.

## Installation

```r
devtools::install_github("richfitz/datastorr")
```

## License

MIT + file LICENSE © [Rich FitzJohn](https://github.com/).
