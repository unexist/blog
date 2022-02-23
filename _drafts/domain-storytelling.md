---
layout: post
title: Domain Storytelling
date: %%%DATE%%%
author: Christoph Kappel
tags: agile domainstory ddd
categories: specification
toc: true
---
It took me quite a while to finish my blog post about
[Logging vs Tracing]({% post_url 2022-02-18-logging-vs-tracing %})

I originally wanted to include my showcase directly in my previous post about
, but after many drafts of it I
made the decision to postpone it to another one to keep topics separated.

So in this post I want to demonstrate a visualization format named [Domain Storytelling][] based
on the showcase about
to
There a few visual formats that really helpI usually try to create a showcase to have something at hand

Visual formats can really help to convey information, especially when the thing you are talking
about is really complex.

I wrote about  in my previous
post and also created a quite complex example in a showcase.

When you try to explain something complex, it can be difficult for the listener to follow without
some kind of visualization for support
for the example to my previous post about

When you are trying to explain a complex scenario to someone el
As I've mentioned earlier, I've prepared a really convoluted example for this post, so let my try
to explain what this is about.
I hadn't had time to start with a post about [Domain Storytelling][], but I think this format is
well-suited to give you an overview about what is supposed to happen:

![image](/assets/images/20220115-overview.png)

This is probably lots of information to the untrained eye, so let me break this down a bit.

### Get the whole story

One of the main drivers of [Domain Storytelling][] is to convey information step-by-step in
complete sentences.
Each step is one action item of the story and normally just covers one specific path - the happy
path here.

This is still probably difficult to grasp, so fire up your browser, it is time to see it for
yourself:

1. Download the [source file][] from the repository.
2. Point your browser to <https://egon.io>.
3. Import the downloaded file with the **up arrow icon** on the upper right.
4. Click on the **play icon** and start the replay.

### How to read it?

When you press play, the modeler hides everything besides the first step:

![image](/assets/images/20220115-step1.png)

And when you are looking at it, try to read it like this:

> A User sends a Todo to the todo-service-create

Can you follow the story and understand the next step? Give it a try with either the **next icon**
the **prev icon** from the toolbar.

{% capture exclamation %}
Before experts blame me: I admit this **digitalized** (includes technology; the preferred way is to
omit it altogether) [Domainstory][] is really broad, but I will conclude on this later - promised.
{% endcapture %}

{% include exclamation.html content=question %}

## Getting the stack ready

During my journey from [Docker][] to [Podman][]
([here]({% post_url 2021-12-01-migrating-to-podman %} and
[here]({% post_url 2021-12-28-one-month-of-podman %}), I've laid down everything that is required
for this scenario, so setting it up should be fairly easy:

<https://github.com/unexist/showcase-logging-tracing-quarkus>

```
https://www.agile-academy.com/en/agile-dictionary/persona/
https://martinfowler.com/bliki/UbiquitousLanguage.html
https://egon.io
https://github.com/unexist/showcase-logging-tracing-quarkus/blob/master/docs/todo.dst
```