#!/bin/zsh

JEKYLL_ENV=production bundle exec jekyll serve --port 10000 --drafts $*
