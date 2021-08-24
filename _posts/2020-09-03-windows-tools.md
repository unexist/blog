---
layout: post
title: Windows tools
date: 2020-09-03 16:30:00 +0200
author: Christoph Kappel
tags: java quarkus maven intellij windows tools
categories: tech
toc: false
---
Oh well - process management under windows is a kind of pain. I especially had to deal with my
[maven][1]/[Quarkus][2]/[IntelliJ][3] combination:

I can easily start [Quarkus][2] and attach a debugger, but [Intellij][3] always fails to stop the
related processes and ends up stuck. For a while, I used the task manager to manually kill the processes.

Sometimes I didn't kill all properly and the port was blocked etc, you probably know the drill.

_wmic_ to the rescue! With it, you can basically use SQL-ish syntax to do funny things like killing
 processes:

###### **Shell:**
```shell
$ wmic process where "commandline like '%%projectname%%jar%%'" delete
```

Just put this inside of a batch file and tell intellij to call it. Et voila!

<https://superuser.com/questions/1003921/how-to-show-full-command-line-of-all-processes-in-windows>

[1]: https://maven.apache.org/
[2]: https://quarkus.io/
[3]: https://www.jetbrains.com/idea/
