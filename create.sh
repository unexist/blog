#!/bin/zsh
TITLE="$*"
FILE="`echo $* | tr '[:upper:]' '[:lower:]' | tr ' ' '-'`.adoc"

cat > "_drafts/$FILE" <<EOF
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
:imagesdir: /assets/images/${FILE}
EOF