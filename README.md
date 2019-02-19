# datastorr

Simple data retrieval and versioning using GitHub

This project is described in a paper ([preprint here])(https://peerj.com/preprints/3401v1) by [Daniel Falster](https://github.com/dfalster/), [Rich FitzJohn](https://github.com/richfitz/), [Matthew Pennell](https://github.com/mwpennell/), and [Will Cornwell](https://github.com/wcornwell/). Below we describe the motivation and general idea. Please see the paper for full details.

## The problem

Over the last several years, there has been an increasing recognition that data is a first-class scientific product and a tremendous about of repositories and platforms have been developed to facilitate the storage, sharing, and re-use of data. However we think there is still an important gap in this ecosystem: platforms for data sharing offer limited functions for distributing and interacting with evolving datasets - those that continue to grow with time as more records are added, errors fixed, and new data structures are created. This is particularly the case for small to medium sized datasets that a typical scientific lab, or collection of labs, might produce.

In addition to enabling data creators to maintain and share a `living` dataset, ideally, such an infrastructure would allow enable data users to:

* Cache downloads, including across R sessions, to make things faster and to work offline
* Keep track of which versions are downloaded and available remotely
* Access multiple versions of the data at once; this would be especially helpful if trying to understand why results have changed with the version of the data.

## How datastorr helps

This package can be used in two ways:

1. Use data stored elsewhere in R efficiently (e.g., work with csv files that are too large to comfortably fit in git).
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

and can see what versions are present on GitHub:

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
devtools::install_github("ropenscilabs/datastorr")
```

## License

MIT + file LICENSE © [Rich FitzJohn](https://github.com/richfitz).
