#!/bin/zsh

DATE="`date +'%Y-%m-%d'`"

ls _drafts | fzf --tac --no-sort | xargs -i -r hg mv _drafts/{} _posts/${DATE}-{}

sed -i -e "s#%%%DATE%%%#${DATE}#" _posts/${DATE}-*.md
