SEMESTER=2026-01
SHELL := /bin/bash
LATEXMK = ./script/latex-wrapper.sh
LATEXMK_FLAGS = -pdf

# Git tracking
GIT = .git/HEAD .git/index
OLD ?= $(shell git rev-parse --short HEAD)
NEW ?= --

# Find all source files
QUESTIONS = $(shell find question -type f 2>/dev/null)
FORMULAS = $(shell find formula -type f 2>/dev/null)
EXPERIMENTS = $(shell find lab-manual -type f -name '*.tex' 2>/dev/null)

# Export for latexmkrc and wrapper script
export FINAL
export INTERACTIVE
export VERBOSE
export OLD
export NEW

# Verbosity control
ifndef VERBOSE
    LATEXMK_FLAGS += -silent
endif

ifdef INTERACTIVE
    LATEXMK_FLAGS += -interaction=nonstopmode
    VERBOSE = 1
endif

# Semester archive targets
.PHONY: semester/%
semester/$(SEMESTER)/%-solution.pdf: %-solution.pdf
	touch $*.tex
	$(MAKE) $*-solution.pdf FINAL=1
	cp $*-solution.pdf $@

semester/$(SEMESTER)2025-08/%.pdf: %.pdf
	touch $*.tex
	$(MAKE) $*.pdf FINAL=1
	cp $*.pdf $@

# Main PDF targets - latexmk handles dependencies automatically
# Removed tidy from individual targets for parallel safety
.PRECIOUS: %.pdf
%-solution.pdf: $(GIT) $(QUESTIONS) $(EXPERIMENTS) macros.tex %.tex
	@echo -e "\n\n=====================================\n$@\n"
	$(LATEXMK) $(LATEXMK_FLAGS) $*.tex

%.pdf: $(GIT) $(QUESTIONS) $(EXPERIMENTS) macros.tex %.tex
	@echo -e "\n\n=====================================\n$@\n"
	$(LATEXMK) $(LATEXMK_FLAGS) $*.tex

# Template generation (unchanged logic)
.PRECIOUS: %-template.tex
%-template.tex: $(GIT) $(QUESTIONS) macros.tex %.tex
	@echo -e "\n\n=====================================\n$@\n"
	@if [ -z "$(FINAL)" ]; then \
		OLD="$(OLD)" NEW="$(NEW)" OPTIONS=$$(./repo/git.sh "$(OLD)" "$(NEW)" 2>/dev/null || echo ""); \
	else \
		OPTIONS=""; \
	fi; \
	latexpand <(latexpand <( echo -E "\documentclass[answers]{exam}$$OPTIONS\input{macros}\input{$*}" )) | \
		vim -c ":%s/\\\\begin{solution}\_.\{-}\\\\end{solution}/\\\\begin{solution}\\\\end{solution}/g" \
		-c "w! $*-template.tex" -c ":q!" -

.PRECIOUS: %-template.pdf
%-template.pdf: %-template.tex
	@echo -e "\n\n=====================================\n$@\n"
	latexmk -pdf $(if $(VERBOSE),,-silent) -jobname=$*-template $*-template.tex

# Phony targets for convenience
.PHONY: assignment/% exam/%
assignment/%: assignment/%.pdf assignment/%-solution.pdf assignment/%-template.pdf
	@echo $@

exam/%: exam/%.pdf exam/%-solution.pdf
	@echo $@

# Cleanup - now separate from compilation for parallel safety
.PHONY: tidy
tidy:
	$(RM) */{*.out,*.log,*.aux,*.synctex.gz,*.blg,*.toc,*.fls,*.fdb_latexmk,*.nav,*.snm}
	$(RM) */{*Notes.bib}

# We can clean up, deleting even the generated template.tex and .pdf, and the .bbl
.PHONY: clean
clean: tidy
	$(RM) -r */*-template.{tex,pdf}
	$(RM) */*.bbl
	latexmk -c 2>/dev/null || true

distclean: clean
	$(RM) -r */*.pdf
	latexmk -C 2>/dev/null || true

# Examples
example: slide/00-unit.pdf note/greek.pdf note/syllabus.pdf exam/00.pdf assignment/00.pdf
example-solution: exam/00-solution.pdf assignment/00-solution.pdf
