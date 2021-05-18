---
layout: post
title: "Windows tools"
date: 2020-09-03 16:30:00 +0200
author: Christoph Kappel
tags: java quarkus maven intellij windows tools
---
Oh well - process management under windows is a kind of pain. I especially had to deal with my
maven/quarkus/intelliJ combination:

I can easily start quarkus and attach a debugger, but intellij always fails to stop the related
processes and ends up stuck. For a while, I used the task manager to manually kill the processes.

Sometimes I didn't kill all properly and the port was blocked etc, you probably know the drill.

_wmic_ to the rescue! With it, you can basically use SQL-ish syntax to do funny things like killing
 processes:

    wmic process where "commandline like '%%projectname%%jar%%'" delete

Just put this inside of a batch file and tell intellij to call it. Et voila!

<https://superuser.com/questions/1003921/how-to-show-full-command-line-of-all-processes-in-windows>
