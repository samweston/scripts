#!/bin/bash

# Edit diary entry. By default edits today's entry. Can optionally pass in a
# number of days previous to edit (e.g. "./edit.sh 1" will edit yesterdays
# diary entry).

# Inspired by https://github.com/samuell/mdnote

set -e

if [ $# -eq 0 ] ; then
    ADJUST_DAYS=0
else
    ADJUST_DAYS=$1
fi

FILE=$(date --date="-$ADJUST_DAYS days" +%Y/%m/%d).md

if [[ ! -d $(dirname "$FILE") ]] ; then
    echo "Creating directory for $FILE"
    mkdir -p "$(dirname "$FILE")"
fi

${EDITOR-vim} $FILE

