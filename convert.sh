OLDFILE=$1
NEWFILE=${1/.md/.adoc}

hg mv $OLDFILE $NEWFILE

# Convert links
sed -i -e "s/\[\([^]]*\)\]\[\([^]]*\)\]/{\2}[\1]/g" $NEWFILE

# Convert marker
sed -i -e "s/^\[\([0-9]*\)\]:/:\1:/g" $NEWFILE

# Convert source
for KIND in java shell hcl log json yaml xml dockerfile cypher ruby; do
    sed -i -e "s/^\`\`\`$KIND/[source,$KIND]\n----/g" $NEWFILE
done

sed -i -e "s/^\`\`\`$/----/g" $NEWFILE

# Convert callouts
sed -i -e "s/\*\*<\([0-9]+\)>\*\*/<\1>/g" $NEWFILE

# Convert headers
sed -i -e "s/##/==/g" $NEWFILE
sed -i -e "s/==#/===/g" $NEWFILE
