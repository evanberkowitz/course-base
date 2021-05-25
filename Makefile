TEX=pdflatex 
BIB=bibtex

# SHELL needed for process substitution <()
SHELL := /bin/bash
REPO=git
OLD?=$(shell git rev-parse --short HEAD)
NEW?=--
ROOT:=$(shell pwd)
GIT= .git/HEAD .git/index

QUESTIONS= $(shell find question -type f)
FORMULAS= $(shell find formula -type f)
BIBS = $(find . -name '*.bib')

ifndef INTERACTIVE
	TEX+=-halt-on-error -interaction=nonstopmode
else
	VERBOSE=1
endif

ifndef VERBOSE
	REDIRECT=1>/dev/null 2>/dev/null
endif

ifndef FINAL
	OPTIONS:=$(shell ./repo/$(REPO).sh $(OLD) $(NEW))
endif

DOCUMENT_CLASS=\documentclass[]{exam}
%-solution.pdf: DOCUMENT_CLASS=\documentclass[answers]{exam}
note/%.pdf: DOCUMENT_CLASS=\documentclass[aps,superscriptaddress,tightenlines,nofootinbib,floatfix,longbibliography,notitlepage]{revtex4-1}
slide/%.pdf: DOCUMENT_CLASS=\documentclass{beamer}\input{slide/macros}

.PRECIOUS: %.pdf
%.pdf %-solution.pdf: $(GIT) $(QUESTIONS) macros.tex %.tex
	@echo $@
	$(TEX) -jobname=$(basename $@) "$(DOCUMENT_CLASS)$(OPTIONS)\input{macros}\input{$*}" $(REDIRECT)
	-$(BIB) $* $(REDIRECT)
	$(TEX) -jobname=$(basename $@) "$(DOCUMENT_CLASS)$(OPTIONS)\input{macros}\input{$*}" $(REDIRECT)
	$(TEX) -jobname=$(basename $@) "$(DOCUMENT_CLASS)$(OPTIONS)\input{macros}\input{$*}" $(REDIRECT)
	$(MAKE) tidy

# Templates are LaTeX files for assignments but with the answers stripped out.
# They are useful for students to be able to submit their responses.
# First, we prepare a tex file that has anything inside of a solution environment deleted.
.PRECIOUS: %-template.tex
%-template.tex: $(GIT) $(QUESTIONS) macros.tex %.tex
	@echo $@
	# This uses latexpand to get everything into a single file, 
	# and then uses a multiline vim regex to replace the solutions with blank spaces.
	
	# latexpand twice to get a fixed point!
	latexpand <(latexpand <( echo -E "\documentclass[answers]{exam}$(OPTIONS)\input{macros}\input{$*}" )) | vim -c ":%s/\\\\begin{solution}\_.\{-}\\\\end{solution}/\\\\begin{solution}\\\\end{solution}/g" -c "w! $*-template.tex" -c ":q!" -

# We compile in an un-fancy way, as a student might, to make sure it works.
.PRECIOUS: %-template.pdf
%-template.pdf: %-template.tex
	@echo $@
	$(TEX) -jobname=$*-template "\input{$*-template}" $(REDIRECT)
	-$(BIB) $* $(REDIRECT)
	$(TEX) -jobname=$*-template "\input{$*-template}" $(REDIRECT)
	$(TEX) -jobname=$*-template "\input{$*-template}" $(REDIRECT)

# Some phony extensionless targets that just do the whole shebang for an assignment or an exam:
.PHONY: assignment/%
assignment/%: assignment/%.pdf assignment/%-solution.pdf assignment/%-template.pdf 
	@echo $@

.PHONY: exam/%
exam/%: exam/%.pdf exam/%-solution.pdf
	@echo $@

# We can tidy up, deleting all the useless TeX auxiliary files.
.PHONY: tidy
tidy:
	$(RM) ./{note/,assignment/,exam/,}*.{out,log,aux,synctex.gz,blg,toc,fls,fdb_latexmk,nav,snm,Notes.bib}

# We can clean up, deleting even the generated template.tex and .pdf, and the .bbl
.PHONY: clean
clean: tidy
	$(RM) -r */*-template.{tex,pdf}
	$(RM) ./{note/,assignment/,exam/,}*.bbl
