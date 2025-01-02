SHELL := /bin/bash

CVFILE = cv

LATEXCMD    = xelatex
LATEXFLAGS  = -interaction=nonstopmode -halt-on-error

all: $(CVFILE).pdf

$(CVFILE).pdf: $(CVFILE).tex
	$(LATEXCMD) $(LATEXFLAGS) $(CVFILE).tex

open: $(CVFILE).pdf
	open $(CVFILE).pdf

clean:
	@rm -f \
		$(CVFILE).aux \
		$(CVFILE).log \
		$(CVFILE).out \
		$(CVFILE).toc \
		$(CVFILE).synctex.gz \
		$(CVFILE).fls \
		$(CVFILE).fdb_latexmk

cleanpdf: clean
	@rm -f $(CVFILE).pdf

.PHONY: all open clean cleanpdf
