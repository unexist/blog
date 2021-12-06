#!/bin/zsh

DATE="`date +'%Y-%m-%d'`"

ls _drafts | fzf --tac --no-sort | xargs -i -r mv _drafts/{} _posts/${DATE}-{}
