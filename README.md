# course-base

This repository provides a skeleton on which to prepare course materials, in the same spirit as evanberkowitz/latex-base.

The idea is to store reusable course materials; with all of the specifics for a semester relegated to a subdirectory of `semester`.

The assumption is that materials will be prepared via LaTeX, and that most macros will be common to the whole course, put in `macros.tex`.  To prepare any given assignment, exam, note, or set of slides one need only use `make`.  Valid obvious examples with the repository as-is include `make assignment/00.pdf`, `make exam/01.pdf`, `make note/greek.pdf`, `make note/syllabus.pdf`, `make slide/01-unit.pdf`.

## Notes

Notes are written materials that you distribute to the class.  The provided examples are a syllabus and a note on the Greek alphabet.  In the `Makefile`, notes are specified to be compiled with `revtex4-1`, with the options

```
note/%.pdf: DOCUMENT_CLASS=\documentclass[aps,superscriptaddress,tightenlines,nofootinbib,floatfix,longbibliography,notitlepage]{revtex4-1}
```

which you can change.

## Assignments and Exams

Assignments and exams are prepared with the [exam class](http://www-math.mit.edu/~psh/exam/examdoc.pdf).  The makefile also provides solution targets, compiled with the `[answers]` option to the exam class.  You compile solutions by just adding `-solution` to the PDF target; `make assignment/00.pdf` and `make exam/01-solution.pdf`, for example.

You can prepare a TeX template for the students to turn in homework, by `make assignment/00-template.tex`.  This uses [`latexpand`](https://www.ctan.org/pkg/latexpand) to make a self-contained document and `vim`'s multiline regex engine to snip out all of your solutions.

I recommend using assignment and exam documents as simple documents, without too much actual course content.  Instead, prepare a set of questions in the `questions` directory and use `\input` to pull them into the document; `\input{question/example}`, for example.

The `question` directory can be organized in whatever way you best see fit---all the questions together, organized by topic, up to you.
The idea is to make it easy to accumulate a large question bank over many semesters and remix and reuse questions.

Similarly, in the `formula` directory you can prepare pieces of formula sheets, if you want to include one on an exam.

## Figures

Image files are extremely annoying to verson control.  For this reason I tend to use `tikz` to prepare simple figures.  `figure/axes-centered.tex`, `figure/axes-trig.tex` and `figure/cosine.tex` are provided as examples; I just copy and paste (and then edit) their contents, as needed.
If I need a fancier image that is more easily prepared with other software (such as Mathematica) I commit the script needed to produce the figure, rather than the figure itself.  My naming convention is to have the script produce a figure with the same name, but that's not enforced; it's up to you.

## Slides

I don't usually teach with slides.  However, I first used this setup in the spring of 2021, teaching remotely because of the SARS-CoV-2 pandemic.  My method was to prepare mostly-empty slides to fill in during lecture.  These slides sometimes used detailed figures or just some bare-bones axes that I could write over without worrying about erasing.

As specified in the `Makefile`, slides are compiled with 

```
slide/%.pdf: DOCUMENT_CLASS=\documentclass{beamer}\input{slide/macros}
```

so that the additional `slide/macros.tex` gets incorporated first, followed by the standard `macros`.  In `slide/macros.tex` you can change the theme, color scheme, which tikz libraries you need, and things of that nature.

## `repo` directory

The `repo` directory contains a script which produces some git-aware macros.  If the repository is clean when triggered, the script colors the information green; red if it is dirty.  I try to only distribute documents from a clean state, so that if a student has a question and something is unclear I can open the exact state of the repo that produced that document.

In provides the `\commit` command, which is just text, and the `\repositoryInformationSetup` command which stamps the left margin with that state of the repo.
