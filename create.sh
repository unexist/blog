#!/bin/zsh
TITLE="$*"
FILENAME="`echo $* | tr '[:upper:]' '[:lower:]' | tr ' ' '-'`"

cat > "_drafts/${FILENAME}.adoc" <<EOF
---
layout: post
title: ${TITLE}
date: %%%DATE%%%
last_updated: %%%DATE%%%
author: Christoph Kappel
tags: showcase
categories: showcase
toc: true
---
:imagesdir: /assets/images/${FILENAME/-/_}
:figure-caption!:
:table-caption!:
EOF
