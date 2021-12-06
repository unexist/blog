#!/bin/zsh

TITLE="$*"
FILE="`echo $* | tr '[:upper:]' '[:lower:]' | tr ' ' '-'`.md"

cat > "_drafts/$FILE" <<EOF
---
layout: post
title: ${TITLE}
date: %%%DATE%%%
author: Christoph Kappel
tags: showcase
categories: showcase
toc: true
---
EOF
