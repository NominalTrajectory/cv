SHELL := /bin/bash

# Directory structure
SRCDIR   = src
BUILDDIR = dist

# Main file
CVFILE = cv

# Add git hash and date variables
GITHASH := $(shell git rev-parse --short HEAD)
GITDATE := $(shell date "+%B %_d, %Y")

# LaTeX commands
LATEXCMD   = xelatex
LATEXFLAGS = -interaction=nonstopmode -halt-on-error -output-directory=../$(BUILDDIR) \
             -jobname=$(CVFILE) \
             '\newcommand{\commitDate}{$(GITDATE)}\newcommand{\commitHash}{$(GITHASH)}\input{$(CVFILE)}'

# Source files
TEXFILES = $(wildcard $(SRCDIR)/*.tex) $(wildcard $(SRCDIR)/config/*.tex)

# Ensure build directory exists
$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

# Main target
all: $(CVFILE).pdf

# Copy final PDF to root directory
$(CVFILE).pdf: $(BUILDDIR)/$(CVFILE).pdf
	@cp $< $@

# Build PDF
$(BUILDDIR)/$(CVFILE).pdf: $(TEXFILES) | $(BUILDDIR)
	cd $(SRCDIR) && $(LATEXCMD) $(LATEXFLAGS) $(CVFILE).tex
	cd $(SRCDIR) && $(LATEXCMD) $(LATEXFLAGS) $(CVFILE).tex

# Watch for changes and rebuild (requires fswatch)
watch:
	@echo "Watching for changes in $(SRCDIR)..."
	@fswatch -o $(SRCDIR) | xargs -n1 -I{} make all

# Open PDF (works on macOS, adjust 'open' for other OS)
open: all
	open $(CVFILE).pdf

# Clean auxiliary files
clean:
	@rm -rf $(BUILDDIR)
	@rm -f \
		$(SRCDIR)/**/*.aux \
		$(SRCDIR)/**/*.log \
		$(SRCDIR)/**/*.out \
		$(SRCDIR)/**/*.toc \
		$(SRCDIR)/**/*.synctex.gz \
		$(SRCDIR)/**/*.fls \
		$(SRCDIR)/**/*.fdb_latexmk

# Clean everything including final PDF
cleanall: clean
	@rm -f $(CVFILE).pdf

.PHONY: all watch open clean cleanall
