---
layout: post
title: Aggregate asciidoc from multiple repositories
date: 2021-06-24 15:24 +0200
author: Christoph Kappel
tags: tools asciidoc antora docs
---
[AsciiDoc][1] is my favorite text processing tool, I basically use it everywhere - well except in
in this blog. It has lots of advantages over [Markdown][2], but don't let us delve into preferences
that aren't the thing I want to write about.

So back to writing documentation in [AsciiDoc][1]: Sometimes there is a
requirement to include docs from multiple sources, but it is kind of difficult to aggregate this
properly and to combine it to a single document.

_There is surely a way to use something like git modules, but there are also not many faster ways
to annoy me._

Antora
----
So time to check out [Antora][3]:

> The multi-repository documentation site generator for tech writers who <3 writing in AsciiDoc.
--- <cite>https://antora.org/</cite>

According to this, this looks really interesting and promising. And after a few hours down the road
I managed to actually generate docs and found a few gotchas.

So here is the general idea about [Antora][3]: On the sourcing side, you just
have a plain yaml file - the [playbook][4] - which contains every source you want to aggregate.
Each of the sources **must be** a working git repository with **at least one** actual commit.

#### **antora-playbook.yml**:
```yaml
site:
  title: Showcase for antora
  url: https://hg.unexist.dev/showcase-antora
  start_page: showcase-architecture-documentation::index.adoc # <1>
content:
  sources:
    - url: https://github.com/unexist/showcase-architecture-documentation.git
      start_path: docs # <2>
ui:
  bundle:
    url: https://gitlab.com/antora/antora-ui-default/-/jobs/artifacts/master/raw/build/ui-bundle.zip?job=bundle-stable
    snapshot
```

**<1>**: This sets the default start page for the whole document and can be from any included source.\
**<2>**: Here the start path in the repository is set; this defines where the **antora.yml** is.

Inside of each repository there has to be another config file - the
[component descriptor][5] - which is read after a checkout of the repository and basically provides
[Antora][3] with a bit of meta informationen

#### **antora.yml**:
```yaml
name: showcase-architecture-documentation
title: Showcase for architecture documentation
version: 0.1.0
start_page: ROOT:index.adoc # <1>
```

**<1>**: This sets the start page of the module.

That is all that is required from the config part - let us talk about the structure. First of all,
there is **no reliable** way to use a custom layout and the [structure][6] from [Antora][3]'s authors
has to be used.

No I am not kidding, see here: [https://gitlab.com/antora/antora/-/issues/28]()

I've tested this for quite some time, here are my learnings:

- There is no way around this fixed structure it; although there is a theoretically way to use
something like [this][7].
- I read symlinks might be a possibility - no they are not; don't waste time here.
- Themes act weird and it is probably better to just keep the default one.

Conclusions
----
When you can really stick to the modules structure this is a really nice tool and probably easier
to use than the java tooling for [AsciiDoc][1].

[1]: https://asciidoctor.org
[2]: https://daringfireball.net/projects/markdown/
[3]: https://antora.org
[4]: https://docs.antora.org/antora/2.3/playbook/set-up-playbook/
[5]: https://docs.antora.org/antora/2.3/component-version-descriptor/
[6]: https://docs.antora.org/antora/2.3/standard-directories/
[7]: https://gitlab.com/djencks/antora-aggregate-collector
