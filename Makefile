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


# Gather all .tex files and the .cls file
TEXFILES = $(wildcard $(SRCDIR)/*.tex) $(wildcard $(SRCDIR)/config/*.tex) $(SRCDIR)/awesome-cv.cls

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

# Preview CV with live reload (requires fswatch: brew install fswatch)
# Opens PDF in Preview.app which auto-refreshes on file changes
preview:
	@echo "Building and opening CV..."
	@$(MAKE) all
	@open $(BUILDDIR)/$(CVFILE).pdf
	@echo "👁️  Watching for changes in $(SRCDIR)... (Press Ctrl+C to stop)"
	@echo "Tip: Keep Preview.app open - it will auto-refresh on changes"
	@fswatch -o $(SRCDIR) | while read; do \
		echo "🔄 Changes detected, rebuilding..."; \
		$(MAKE) all; \
	done



# ------------------------------------------------------------------------
# 3) COVER LETTER TARGETS
# ------------------------------------------------------------------------

COVERDIR = cover-letters

# Build a specific cover letter (interactive selection)
cover-letter:
	@if [ ! -d "$(COVERDIR)" ] || [ -z "$$(ls -A $(COVERDIR)/*.tex 2>/dev/null)" ]; then \
		echo "No cover letters found in $(COVERDIR)/"; \
		exit 1; \
	fi
	@echo "Available cover letters:"
	@i=1; for f in $(COVERDIR)/*.tex; do \
		name=$$(basename "$$f" .tex); \
		echo "  $$i) $$name"; \
		i=$$((i + 1)); \
	done
	@read -p "Select letter number: " num; \
	i=1; for f in $(COVERDIR)/*.tex; do \
		if [ $$i -eq $$num ]; then \
			name=$$(basename "$$f" .tex); \
			echo "Building $$name..."; \
			mkdir -p $(BUILDDIR); \
			cd $(SRCDIR) && $(LATEXCMD) -interaction=nonstopmode -halt-on-error \
				-output-directory=../$(BUILDDIR) \
				-jobname=cover_letter_$$name \
				"\newcommand{\commitDate}{$(GITDATE)}\newcommand{\commitHash}{$(GITHASH)}\input{../$(COVERDIR)/$$name}"; \
			echo "Output: $(BUILDDIR)/cover_letter_$$name.pdf"; \
			exit 0; \
		fi; \
		i=$$((i + 1)); \
	done; \
	echo "Invalid selection"; exit 1

# Build a specific cover letter by name: make cover-letter-playstation
cover-letter-%:
	@if [ ! -f "$(COVERDIR)/$*.tex" ]; then \
		echo "Cover letter not found: $(COVERDIR)/$*.tex"; \
		exit 1; \
	fi
	@mkdir -p $(BUILDDIR)
	@echo "Building $*..."
	@cd $(SRCDIR) && $(LATEXCMD) -interaction=nonstopmode -halt-on-error \
		-output-directory=../$(BUILDDIR) \
		-jobname=cover_letter_$* \
		"\newcommand{\commitDate}{$(GITDATE)}\newcommand{\commitHash}{$(GITHASH)}\input{../$(COVERDIR)/$*}"
	@echo "Output: $(BUILDDIR)/cover_letter_$*.pdf"

# ------------------------------------------------------------------------
# 4) CLEANUP
# ------------------------------------------------------------------------

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



.PHONY: all watch open preview clean cleanall docker-build docker-run docker-all cover-letter
