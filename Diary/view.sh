#!/bin/bash

# Generates an HTML view of the diary entries and opens using the default
# browser. Can optionally pass in the directory you wish to view (e.g. 2017/05/
# to view the entries from May 2017).

# Inspired by https://github.com/samuell/mdnote

if [ $# -eq 0 ] ; then
    VIEW_PATH=.
else
    VIEW_PATH=$1
fi

OUTPUT_FILE=gen.html
#OUTPUT_FILE=gen.pdf

REGEX=".*([0-9][0-9][0-9][0-9])/([0-9][0-9])/([0-9][0-9])\.md"

if type pandoc &> /dev/null ; then
    find $VIEW_PATH -name *.md | sort -r | while read line ; do
        if [[ $line =~ $REGEX  ]] ; then
            YEAR=${BASH_REMATCH[1]}
            MONTH=${BASH_REMATCH[2]}
            DAY=${BASH_REMATCH[3]}
            # Inject a date header.
            echo "# $(date --date ${YEAR}${MONTH}${DAY} "+%A, %e, %B, %Y")"
            cat $line
            echo ""
        else
            (>&2 echo "$line does not match")
            exit 1
        fi
    done | pandoc -o $OUTPUT_FILE
    if type xdg-open &> /dev/null ; then
        xdg-open $OUTPUT_FILE &> /dev/null
    else
        echo "xdg-open not found"
    fi
else
    echo "pandoc not found"
fi

