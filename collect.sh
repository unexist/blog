#!/bin/zsh
FILE="$1"
IDX=1

while read LINK; do
    LINKNAME=`echo $LINK | cut -d "]" -f 1 | tr -d "[]"`

    # Respect case
    LINKNAME_UP=`echo ${LINKNAME:0:1} | tr '[:lower:]' '[:upper:]'`${LINKNAME:1}
    LINKNAME_DOWN=`echo ${LINKNAME:0:1} | tr '[:upper:]' '[:lower:]'`${LINKNAME:1}

    sed -i -e "s#\[${LINKNAME_UP}\]\[[0-9]*\]#{${IDX}}\[${LINKNAME_UP}\]#g" "$FILE"
    sed -i -e "s#\[${LINKNAME_DOWN}\]\[[0-9]*\]#{${IDX}}\[${LINKNAME_DOWN}\]#g" "$FILE"

    LINKNAME=`echo $LINKNAME | tr -d ' '`

    echo ":$IDX: <$LINKNAME>" >> "$FILE"

    IDX=`expr $IDX + 1`
done < <(\grep -oh "\[[^[]*\]\[[0-9]*\]" "$FILE" | sort -uf)
