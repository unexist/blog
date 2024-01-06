#!/bin/zsh
TITLE="$*"
FILENAME="`echo $* | tr '[:upper:]' '[:lower:]' | tr ' ' '-'`"
PATHNAME="${FILENAME//-/_}"

cat > "_drafts/${FILENAME}.adoc" <<EOF
---
layout: post
title: ${TITLE}
description: TBD
#date: %%%DATE%%%
#last_updated: %%%DATE%%%
author: Christoph Kappel
tags: showcase
categories: tech
toc: true
---
ifdef::asciidoctorconfigdir[]
:imagesdir: {asciidoctorconfigdir}/../assets/images/${PATHNAME}
endif::[]
ifndef::asciidoctorconfigdir[]
:imagesdir: /assets/images/${PATHNAME}
endif::[]
:figure-caption!:
:table-caption!:
EOF
