SHELL := /bin/bash

# Directory structure
SRCDIR   = src
BUILDDIR = dist

# Main file
CVFILE = cv

# Git hash and date variables
GITHASH := $(shell git rev-parse --short HEAD)
GITDATE := $(shell date "+%B %_d, %Y")

# LaTeX commands (for local builds, if desired)
LATEXCMD   = xelatex
LATEXFLAGS = -interaction=nonstopmode -halt-on-error -output-directory=../$(BUILDDIR) \
             -jobname=$(CVFILE) \
             '\newcommand{\commitDate}{$(GITDATE)}\newcommand{\commitHash}{$(GITHASH)}\input{$(CVFILE)}'

# Gather all .tex files
TEXFILES = $(wildcard $(SRCDIR)/*.tex) $(wildcard $(SRCDIR)/config/*.tex)

# Ensure build directory exists
$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

# ------------------------------------------------------------------------
# 1) LOCAL BUILD TARGETS
# ------------------------------------------------------------------------

# "all" = produce PDF and PNG locally (requires xelatex & magick installed locally)
all: $(BUILDDIR)/$(CVFILE).pdf $(BUILDDIR)/$(CVFILE).png

# Build the PDF locally
$(BUILDDIR)/$(CVFILE).pdf: $(TEXFILES) | $(BUILDDIR)
	cd $(SRCDIR) && $(LATEXCMD) $(LATEXFLAGS) $(CVFILE).tex
	cd $(SRCDIR) && $(LATEXCMD) $(LATEXFLAGS) $(CVFILE).tex

# Convert PDF to PNG locally
$(BUILDDIR)/$(CVFILE).png: $(BUILDDIR)/$(CVFILE).pdf
	@magick convert -density 300 $< -background white -alpha remove -alpha off -quality 100 $@

# Watch for changes (local) and rebuild
watch:
	@echo "Watching for changes in $(SRCDIR)..."
	@fswatch -o $(SRCDIR) | xargs -n1 -I{} make all

# Open PDF on macOS
open: all
	open $(BUILDDIR)/$(CVFILE).pdf

# Clean intermediate build files
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

# Clean including final PDF and PNG
cleanall: clean
	@rm -f $(CVFILE).pdf
	@rm -f $(BUILDDIR)/$(CVFILE).png

# ------------------------------------------------------------------------
# 2) DOCKER-BASED BUILD TARGETS
# ------------------------------------------------------------------------

# Name for our Docker image
DOCKER_IMAGE = my-cv

# Build the Docker image (one-time or whenever Dockerfile changes)
docker-build:
	@docker build -t $(DOCKER_IMAGE):latest .

# Run the build inside Docker
# This will mount the current directory into /work in the container,
# then run "make all" (the local Make target) inside Docker.
docker-run: docker-build
	@docker run --rm \
		-e GITHASH=$(GITHASH) \
		-e GITDATE="$(GITDATE)" \
		-v $(PWD):/work \
		-w /work \
		$(DOCKER_IMAGE):latest \
		make all

# Convenience target: build+run in one go
docker-all: docker-build docker-run

.PHONY: all watch open clean cleanall docker-build docker-run docker-all
