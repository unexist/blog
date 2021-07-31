---
layout: post
title: Multiline commands in makefiles
date: 2021-05-21 16:27 +0200
author: Christoph Kappel
tags: tools makefile
categories: tech
---
Using multiline commands in [make][1] is usually a pain, I've tried so many ways and still you
either have to use arcane extensions or just use a separate file that can be called from the
makefile.

A pretty easy way to still achieve what you probably want to do is to use [define][2]:

###### **Makefile**:
```makefile
define JSON_TODO # <1>
curl -X 'POST' \
  'http://localhost:8080/todo' \
  -H 'accept: */*' \
  -H 'Content-Type: application/json' \
  -d '{
  "description": "string",
  "done": true,
  "dueDate": {
    "due": "2021-05-07",
    "start": "2021-05-07"
  },
  "title": "string"
}'
endef
export JSON_TODO # <2>

todo:
	@echo $$JSON_TODO | bash # <3>
```
**<1>** This defines the variable **JSON_TODO** and sets the followed content separated by semicolons.\
**<2>** The export is required to make this accessible to the shell.\
**<3>** And this finally pipes the content of the variable through a bash shell.

[1]: https://www.gnu.org/software/make/
[2]: https://www.gnu.org/software/make/manual/make.html#index-define