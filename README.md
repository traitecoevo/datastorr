# dataverse

> Simple Data Versioning

Simple data versioning using GitHub to store data.

This package is designed to be used by other package authors, not directly by downstream end users.

## End user experience

See [here](https://github.com/richfitz/dataverse.example) for the aim from the point of view for an end user.


They would install your package:

```r
devtools::install_github("richfitz/dataverse.example")
```

See what versions you have:

```r
dataverse.example::mydata_versions() # local
dataverse.example::mydata_versions(local=FALSE) # remote
```

Download the most recent dataset

```r
d <- dataverse.example::mydata()
```

Subsequent calls (even across R sessions) are cached so that the mydata() function is fast enough you can use it in place of the data.

To get a particular version:

```r
d <- dataverse.example::mydata("0.0.1")
```

## Package developer process

For now, see the file [here](https://github.com/richfitz/dataverse.example/blob/master/R/package.R).

## Installation

```r
devtools::install_github("richfitz/storr@simplify")
devtools::install_github("richfitz/dataverse")
```

## License

MIT + file LICENSE © [Rich FitzJohn](https://github.com/).
