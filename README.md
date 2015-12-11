# datastorr

Simple data versioning using GitHub to store data.

This package is designed to be used by other package authors, not directly by downstream end users.

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
devtools::install_github("richfitz/storr@refactor")
devtools::install_github("richfitz/datastorr")
```

## License

MIT + file LICENSE © [Rich FitzJohn](https://github.com/).
