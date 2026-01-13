#!/bin/bash
# script/latex-wrapper.sh - Parallel-safe LaTeX wrapper that injects document class and macros

set -e

# The base file is the last argument, flags come first
# e.g., ./script.sh -pdf -silent assignment/00.tex
BASE="${@: -1}"  # Last argument
# Remove the last argument to get just the flags
set -- "${@:1:$(($#-1))}"

# Get the repository root (where this script is called from)
REPO_ROOT="$(pwd)"

# Create unique temp file in the repo root so relative paths work
# Use a distinctive prefix to avoid any conflicts
TMPFILE=$(mktemp "${REPO_ROOT}/.latex-wrapper-$$-XXXXXX.tex" 2>/dev/null || \
          mktemp "${REPO_ROOT}/.latex-wrapper-$$.tex")

# Cleanup on exit (even if interrupted)
# Only remove the exact temp file we created - never touch source files
trap "rm -f '$TMPFILE' '${TMPFILE%.tex}.pdf' '${TMPFILE%.tex}.aux' '${TMPFILE%.tex}.log' '${TMPFILE%.tex}.bbl' '${TMPFILE%.tex}.blg' '${TMPFILE%.tex}.out' '${TMPFILE%.tex}.fdb_latexmk' '${TMPFILE%.tex}.fls' 2>/dev/null" EXIT INT TERM

# Determine document configuration
DOC_CLASS="\\documentclass[]{exam}"
MACROS="\\input{macros}"
OPTIONS=""

# Check if FINAL is set
if [ -z "$FINAL" ]; then
    OLD="${OLD:-$(git rev-parse --short HEAD 2>/dev/null || echo HEAD)}"
    NEW="${NEW:---}"
    OPTIONS=$(./repo/git.sh "$OLD" "$NEW" 2>/dev/null || echo "")
fi

# Determine document type based on base filename
if [[ "$BASE" == *"-solution.tex" ]]; then
    DOC_CLASS="\\documentclass[answers]{exam}"
    BASE="${BASE%-solution.tex}"
elif [[ "$BASE" == note/* ]]; then
    DOC_CLASS="\\documentclass[aps,superscriptaddress,tightenlines,nofootinbib,floatfix,longbibliography,notitlepage]{revtex4-1}"
elif [[ "$BASE" == slide/* ]]; then
    # For slides, pass dvipsnames option to xcolor before beamer loads it
    # Then load slide/macros and regular macros.tex (slides need macros.tex for \class, etc.)
    DOC_CLASS="\\PassOptionsToPackage{dvipsnames}{xcolor}\\documentclass{beamer}\\input{slide/macros}"
fi

# Add solution.tex for assignments, exams, quizzes
if [[ "$BASE" == assignment/* || "$BASE" == exam/* || "$BASE" == quiz/* ]]; then
    MACROS+="\\input{solution}"
fi

# Create temporary wrapper file with injected preamble
cat > "$TMPFILE" <<EOF
$DOC_CLASS$OPTIONS$MACROS
\input{$BASE}
EOF

# Determine jobname from original base (full path without .tex extension)
# This ensures bibtex and other tools use the correct paths
JOBNAME="${BASE%.tex}"

# Run latexmk on the temp file with the correct jobname
# This ensures bibtex uses the correct base name and paths
# $@ contains flags like -pdf -silent from the Makefile
latexmk -pdf -silent -jobname="$JOBNAME" "$TMPFILE"

# The PDF should already be in the correct location due to jobname
# But verify and move if needed (in case of any edge cases)
if [ -f "${JOBNAME}.pdf" ]; then
    # Already in the right place, nothing to do
    :
elif [ -f "${TMPFILE%.tex}.pdf" ]; then
    # Fallback: move from temp location
    mv "${TMPFILE%.tex}.pdf" "${JOBNAME}.pdf"
fi

# Move any auxiliary files that might have been created in the repo root
# to the correct directory (this handles cases where bibtex creates files
# in the current directory instead of relative to jobname)
JOBNAME_BASENAME="${JOBNAME##*/}"
JOBNAME_DIR="${JOBNAME%/*}"
if [ "$JOBNAME_DIR" != "$JOBNAME" ] && [ "$JOBNAME_DIR" != "." ]; then
    # We have a subdirectory - check for files created in root with just the basename
    for ext in bbl blg aux log out fdb_latexmk fls; do
        if [ -f "${JOBNAME_BASENAME}.${ext}" ] && [ ! -f "${JOBNAME}.${ext}" ]; then
            mv "${JOBNAME_BASENAME}.${ext}" "${JOBNAME}.${ext}" 2>/dev/null || true
        fi
    done
    # Handle Notes.bib files specially (revtex creates these)
    if [ -f "${JOBNAME_BASENAME}Notes.bib" ] && [ ! -f "${JOBNAME}Notes.bib" ]; then
        mv "${JOBNAME_BASENAME}Notes.bib" "${JOBNAME}Notes.bib" 2>/dev/null || true
    fi
fi

