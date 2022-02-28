---
layout: post
title: Domain Storytelling
date: %%%DATE%%%
author: Christoph Kappel
tags: domainstory ddd showcase
categories: specification showcase
toc: true
---
My previous post about [Logging vs Tracing]({% post_url 2022-02-18-logging-vs-tracing %} is
probably the one with the most upfront preparation so far.
I had ambitious plans for it and wanted to explain the general topic, cover the necessary basics
and demonstrate the differences of both on a slightly contrived example later on.

I added more and more tech to it and quickly ran into trouble explaining how everything is set up
and also what the actual usecase is supposed to do.

So in this follow-up post I want to demonstrate the visualization format [Domain Storytelling][]
based on my previous example and introduce you to its unique way of conveying information.

### Get the whole story

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