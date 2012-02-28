#!/bin/bash

REPOS_BASE_URL="http://www3.zq1.de/bernhard/linux/yast/"
ALL_REPOS=`curl ${REPOS_BASE_URL} 2>/dev/null | html2text -width 800 | grep "\[DIR\]" | sed 's/\[\[DIR\]\] \(.*\.git\)\/.*/\1/' | grep "\.git"`
CHECKOUTDIR="git_checkout"

# Modules known to be already discontinued
DISCONTINUED_MODULES=`pwd`"/discontinued_modules"

echo "============================================="
LANG=C date
echo "============================================="

mkdir -p ${CHECKOUTDIR}
cd ${CHECKOUTDIR} || exit 1
BASEDIR=`pwd`

# @param string directory name (on disk)
# @param string repository name (with .git)
function clone_from_scratch () {
    cd ${BASEDIR}
    rm -rf $1
    git clone ${REPOS_BASE_URL}$2 1>>$3 2>>$3

    return $?
}

function pull_from_git () {
    cd ${BASEDIR}
    cd $1
    git pull 2>/dev/null

    return $?
}

function check_one_repo_param () {
    CHECKED=`LC_ALL=C echo "$1" | sed 's/[a-zA-Z0-9_\.-]//g'`
    if [ "${CHECKED}" != "" ]; then
        echo; echo; echo "Error processing \"$1\""
        echo "Forbidden characters: ${CHECKED}"
        exit 1
    fi

    return 0
}

for ONE_REPO in ${ALL_REPOS}; do
        #if [ "${ONE_REPO}" == "yast-add-on.git" ] || [ "${ONE_REPO}" == "yast-ipsec.git" ]; then

        # security check
        check_one_repo_param ${ONE_REPO}

        echo "Processing \"${ONE_REPO}\""
        echo "--------------------------------"
        REPO_DIR=`echo "${ONE_REPO}" | sed 's/\.git//'`
        TMPFILE=`mktemp`

        DISCONTINUED=`grep "^${REPO_DIR}$" ${DISCONTINUED_MODULES}`

        cd ${BASEDIR}

        if [ -e "${REPO_DIR}" ]; then
            pull_from_git ${REPO_DIR} || clone_from_scratch ${REPO_DIR} ${ONE_REPO} ${TMPFILE}
        else
            clone_from_scratch ${REPO_DIR} ${ONE_REPO} ${TMPFILE}
        fi

        if [ "${DISCONTINUED}" == "${REPO_DIR}" ]; then
            echo "Module has been discontinued"
            grep -v "warning: remote HEAD refers to nonexistent ref, unable to checkout." ${TMPFILE}
        else
            cat ${TMPFILE}
        fi

        cd ${BASEDIR}/${REPO_DIR}

        echo; echo "Checking ${REPO_DIR}..."

        NR_OF_BRANCHES=`LC_ALL=C git branch -a | wc -l`
        NR_OF_TAGS=`LC_ALL=C git tag | wc -l`
        NR_OF_COMMITS=`LC_ALL=C git log | grep ^commit | wc -l`

        if [ ${NR_OF_BRANCHES} -eq 0 ]; then
            echo "(${REPO_DIR}) ERROR: No branches available"
        elif [ ${NR_OF_BRANCHES} -eq 1 ]; then
            echo "(${REPO_DIR}) WARNING: Only one branch available"
        else
            echo "- There are ${NR_OF_BRANCHES} branches"
        fi

        if [ ${NR_OF_TAGS} -eq 0 ]; then
            echo "(${REPO_DIR}) WARNING: No tags available"
        else
            echo "- There are ${NR_OF_TAGS} tags"
        fi

        echo "- There are ${NR_OF_COMMITS} commits in the current branch"

        rm -rf ${TMPFILE}

        echo
        #fi
done

exit 0
