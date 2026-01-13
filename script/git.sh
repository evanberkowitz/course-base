#!/usr/bin/env bash

OLD=$1
NEW=$2

THIS=$(realpath $0)
GIT=$(dirname ${THIS})/..

if [ -z "$OLD" ]; then
	OLD=HEAD
fi

if [ -z "$NEW" ]; then
	NEW="--"
fi

pushd ${GIT} 2>/dev/null 1>/dev/null

files_changed=$(git diff --name-only ${OLD} ${NEW} 2>/dev/null | wc -l | tr -d [:blank:])

# Get the short commit hash, with fallback that handles ~ characters
SHORT_COMMIT=$(git rev-parse --short ${OLD} 2>/dev/null || echo "${OLD}")
SHORT_COMMIT=${SHORT_COMMIT/\~/\{\\textasciitilde\}}

# Build message based on whether repo is clean or dirty
if [[ "${files_changed}" == "0" ]]; then
    # Clean repo - simple message
    result="{\color{ForestGreen}\\texttt{git commit ${SHORT_COMMIT}}}"
    commit="{\color{ForestGreen}${SHORT_COMMIT}}"
else
    # Dirty repo - show difference message
    if [[ "${files_changed}" == "1" ]]; then
        files_text="${files_changed} file differs"
    else
        files_text="${files_changed} files differ"
    fi
    result="{\color{red}${files_text} from \\texttt{git commit ${SHORT_COMMIT}}}"
    commit="{\color{red}${SHORT_COMMIT}}"
fi

result="\newcommand{\repositoryInformationSetup}{
    \usepackage[ angle=90, color=black, opacity=1, scale=2, ]{background} 
    \SetBgPosition{current page.west} 
    \SetBgVshift{-4.5mm} 
    \backgroundsetup{contents={${result}}}
}
\newcommand{\commit}{{${commit}}}"

popd 2>/dev/null 1>/dev/null

echo "${result}"