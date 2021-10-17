#!/bin/zsh
set -x
FILE="$1"
IDX=1

while read LINK; do
    LINKNAME=`echo $LINK | cut -d "]" -f 1 | tr -d "[]"`

    sed -i -e "s#\[${LINKNAME}\]\[[0-9]*\]#\[$LINKNAME\]\[$IDX\]#g" $FILE

    echo "[$IDX]: $LINKNAME" >> $FILE

    IDX=`expr $IDX + 1`
done < <(\grep -oh "\[[^[]*\]\[[0-9]*\]" $FILE | sort -u)
