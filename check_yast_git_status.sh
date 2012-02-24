#!/bin/bash

REPOS_BASE_URL="http://www3.zq1.de/bernhard/linux/yast/"
ALL_REPOS=`curl ${REPOS_BASE_URL} 2>/dev/null | html2text -width 800 | grep "\[DIR\]" | sed 's/\[\[DIR\]\] \(.*\.git\)\/.*/\1/' | grep "\.git"`
CHECKOUTDIR="git_checkout"

echo "============================================="
LANG=C date
echo "============================================="

mkdir -p ${CHECKOUTDIR}
cd ${CHECKOUTDIR} || exit 1
BASEDIR=`pwd`

for ONE_REPO in ${ALL_REPOS}; do
	#if [ "${ONE_REPO}" == "yast-add-on.git" ]; then

	echo "Processing \"${ONE_REPO}\""
	echo "--------------------------------"
        REPO_DIR=`echo "${ONE_REPO}" | sed 's/\.git//'`

	if [ -e "${REPO_DIR}" ]; then
	    cd ${REPO_DIR}
	    git pull || (cd ../; rm -rf ${REPO_DIR}; git clone ${REPOS_BASE_URL}${ONE_REPO}; cd ${REPO_DIR})
	else
	    git clone ${REPOS_BASE_URL}${ONE_REPO}
	    cd ${REPO_DIR}
	fi

        NR_OF_BRANCHES=`git branch -a | wc -l`
        NR_OF_TAGS=`git tag | wc -l`

        echo "- There are ${NR_OF_BRANCHES} branches in ${REPO_DIR}"
        echo "- There are ${NR_OF_TAGS} tags in ${REPO_DIR}"

        echo
        cd ${BASEDIR}

	#fi
done
