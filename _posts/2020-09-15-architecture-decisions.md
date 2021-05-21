---
layout: post
title: Architecture decisions
date: 2020-09-15 08:00:00 +0200
author: Christoph Kappel
tags: tools architecture docs
---
Yesterday we had another discussion about architecture documentation and especially about decisions
made about it. We came to a quick agreement, that the form makes no difference, but that there
**is** a dire need for a way to see, **why** something is like it is.

One of the tooling suggestions here is [ADR](https://adr.github.io/)
([repo](https://github.com/npryce/adr-tools)), which basically is just a helper for easy to handle
markdown files, which can either be placed next to the code (for microservices) or into a dedicated
repository. (for macroarchitecture)

I am always in favor to have docs next to code, so the chance that; a) someone really reads it and
more importantly b) keeps it up to date is better. From my experience a wiki is just a collection
of outdated files: *Barely read; never updated*.

Now that we have nice tools for our handiwork, we have to think about **who** writes docs and first
and foremost **when**?

The latter is really easy, whenever a decision is made like which technology stack, which testing
framework and so on, just write an entry.

And the answer to the first question? **Probably you!**
