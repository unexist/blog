#!/bin/zsh
DATE="`date +'%Y-%m-%d'`"
DATEZ="`date +'%Y-%m-%d %H:%M %z'`"

ls _drafts | fzf --tac --no-sort | xargs -i -r hg mv _drafts/{} _posts/${DATE}-{}

sed -i -e "s#%%%DATE%%%#${DATEZ}#g" _posts/${DATE}-*.adoc