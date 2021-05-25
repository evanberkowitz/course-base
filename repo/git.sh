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

# Double hyphens is a ligature in TeX:
if [ "--" == "${NEW}" ]; then
	NEWPRINT="-{}-"
else
	NEWPRINT="${NEW}"
fi

# Handle commit IDs that have ~ in them, like HEAD~3
OLDPRINT=${OLD/\~/\{\\textasciitilde\}}
NEWPRINT=${NEWPRINT/\~/\{\\textasciitilde\}}

pushd ${GIT} 2>/dev/null 1>/dev/null

echo "Deducing diff..." >&2

echo git branches are >&2
git branch -vv >&2

echo OLD is ${OLD} >&2
echo NEW is ${NEW} >&2
files_changed=`git diff --name-only ${OLD} ${NEW} 2>/dev/null | wc -l | tr -d [:blank:]`

if [[ "${files_changed}" == "1" ]]; then
	files_changed="${files_changed} file"
else
	files_changed="${files_changed} files"
fi

result='\texttt{'"${NEWPRINT}"'} differs from commit \texttt{'"${OLDPRINT}"'}'" in ${files_changed}"

# Turn red if there are dirty files.
if [[ ! "${files_changed:0:1}" == "0" ]]; then
    result="{\color{red}${result}}"
    commit="{\color{red}${OLDPRINT}}"
else
    result="{\color{green}${result}}"
    commit="{\color{green}${OLDPRINT}}"
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
