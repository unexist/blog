---
layout: post
title: Learnings from using ADR in a real project
date: 2021-08-18 17:07 +0200
author: Christoph Kappel
tags: tools architecture adr
categories: architecture warstory
toc: true
---
I am about to leave my current project, so it is time to reflect on how well the whole [ADR][1]
idea went. As I've mentioned in a
[previous post]({% post_url 2020-09-15-architecture-decisions %}), the overall idea was to have
a clear format and single-source-of-truth to document all relevant architecture decisions.

## What problems did we face?

### Scope of the records

So the initial question was what belongs into a record and what not? Unfortunately we never really
found out and are having a wild mix now, with quite different records. Some of them describe more
the philosophy of the project, some describe macro-architectural decisions and others just evaluate
different aspects of technology without a real conclusion.

***

_A clear learning here is to separate **micro** and **marco** architecture from each other, to avoid
lots of confusion of the intended audience - namely developers._

### Format

Originally geared toward [Markdown][2]-only, we soon reached a limit what can be done with it and
we've already made the general decision to use [AsciiDoc][3] as a documentation format. So I
basically picked up an [abandoned pull-request][4] which adds this support and also updated the
[adr-tools][5] to better reflect our way of working.
([See here]({% post_url 2021-03-15-adr-and-jqassistant %}))

***

_Although switching to [AsciiDoc][3] eased the handling for us writers, it never got much buy in by
the teams. The overall preference there was to have a [Confluence][6] page, to be able to add
comments and have everything just in one place._

### Size

Laying out the context of an [ADR][1] is sometimes a bit difficult and requires lots of
explanations and reasoning, but it probably should never end in just gossip. So we clearly

### Single page

The default output for [AsciiDoc][3] is a single page, so handling of it, when there are 40-50
records included, is quite difficult. Also the tooling gets slower and I had to add indexing via
[sqlite][7].

***

_We haven't found a real solution yet, there is a way to split it up, but I have to look into it
as my last task on this._

### Fitness functions

[ADR][1] define a fixed structure, but what our version was lacking is a section with either a
fitness function or some other means to test, if this [ADR][1] has been followed. So we ended up
with several records (about 60) and had no means of verifying them.

***

_In my post about [ADR and jqAssistant]({% post_url 2021-03-15-adr-and-jqassistant %}) I basically
laid out how this can be easily done with [jqAssistant][8], but we never had the time to look into
that._

## Conclusion

[ADR][1] are a nice way to document architectural decisions, if the scope of the records is kept,
it is clearly outlined what this all is about and there is some kind of possible verification.

[1]: https://adr.github.io/
[2]: https://daringfireball.net/projects/markdown/
[3]: https://asciidoc.org/
[4]: https://github.com/npryce/adr-tools/pull/101
[5]: https://github.com/npryce/adr-tools
[6]: https://www.atlassian.com/software/confluence
[7]: https://www.sqlite.org/index.html
[8]: https://jqassistant.org/