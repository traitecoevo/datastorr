PACKAGE := $(shell grep '^Package:' DESCRIPTION | sed -E 's/^Package:[[:space:]]+//')
RSCRIPT = Rscript --no-init-file

all: install

test:
	DATASTORR_SKIP_DOWNLOADS=true make test_all

test_all:
	${RSCRIPT} -e 'library(methods); devtools::test()'

roxygen:
	@mkdir -p man
	${RSCRIPT} -e "library(methods); devtools::document()"

install:
	R CMD INSTALL .

build:
	R CMD build .

check:
	DATASTORR_SKIP_DOWNLOADS=true make check_all

check_all: build
	_R_CHECK_CRAN_INCOMING_=FALSE R CMD check --as-cran --no-manual `ls -1tr ${PACKAGE}*gz | tail -n1`
	@rm -f `ls -1tr ${PACKAGE}*gz | tail -n1`
	@rm -rf ${PACKAGE}.Rcheck

vignettes/datastorr.Rmd: vignettes/src/datastorr.R
	${RSCRIPT} -e 'library(sowsear); sowsear("$<", output="$@")'
vignettes: vignettes/datastorr.Rmd
	${RSCRIPT} -e 'library(methods); devtools::build_vignettes()'

staticdocs:
	@mkdir -p inst/staticdocs
	${RSCRIPT} -e "library(methods); staticdocs::build_site()"
	rm -f vignettes/*.html
	@rmdir inst/staticdocs
website: staticdocs
	./update_web.sh

# No real targets!
.PHONY: all test document install vignettes
