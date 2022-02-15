---
layout: post
title: Domain Storytelling
date: %%%DATE%%%
author: Christoph Kappel
tags: agile ddd
categories: specification
toc: true
---
In my previous post about
[Specification by Example]({% post_url 2021-09-09-specification-by-example %}) I pointed out, that
for me communication is a major problem within software projects and I suggested [specification
workshops][] as a way to transport the intent of a specific feature. This probably works best in
agile projects with short sprints, so that there is no need to define everything upfront.

What if we have to define everything upfront, because there are waterfall-y processes in place and
there is no short term plan to go agile?

## Specifications first

I probably know what you are thinking, but let us pretend we have a magic crystal ball and can
predict the distant future. I'd like to shift our focus to some other problems:

### What is the targeted audience?

Writing in general is difficult. When you are an expert in some field, you have a good depth of
knowledge and you automatically assume the reader of your specification shares this depth. This
obviously leads to a lack of detail and overall looser descriptions. I haven't checked this yet, but
I assume the manual on how to remove a combustion engine from a car for technical folks is
something, that I don't easily grasp.

**Hint**: A nice trick from the agile community is to define [personas][] for the targeted
audience. They create a fictional person, fill in some details like hobbies, pictures etc and
and then try to impersonate this person while writing stories.

### What do you mean by that?

Have you ever been present, when you two doctors talk about medical findings? They probably used
lots of unknown words or ones with different meaning in their specific context. This is especially
helpful in anatomy, to rule out ambiguity, but makes it really complicated for the uninitiated to
follow.

**Hint**: In [Domain-Driven Design][] the concept of an [ubiquitous language][] is an essential
part of the domain model. It evolves along with the model and helps all participants to ~~sound like
doctors~~ reduce ambiguity.

### When is long too long?

The length of a specification is also a difficult topic. In agile, stories are just a reminder for
people who had a discussion about a particular feature, so it is perfectly fine when the stories
just include the gist of it. Upfront, more explanation is required and sometimes leads to whole
screens of prosa and it is difficult to get the gist of it.

In the agile world there is a saying:

>If you run out of space use smaller cards.
<cite>Unknown</cite>

## Domain Storytelling

I recently stumbled upon another method of modelling
[Domain Storytelling][] is collaborative and graphical modelling tool

![image](/assets/images/20211209-overview.png)


## Example time

### Tell a Domainstory

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

### Docker

If you want to start with [Docker][], just do the following and fire up [docker-compose][]:

###### **Shell**:
```shell
$ svn export https://github.com/unexist/showcase-logging-tracing-quarkus/trunk/docker
A    docker
A    docker/Makefile
A    docker/collector
A    docker/collector/otel-collector-config.yaml
A    docker/docker-compose.yaml
A    docker/fluentd
A    docker/fluentd/Dockerfile
A    docker/fluentd/fluent.conf
Exported revision 107.

$ make -f docker/Makefile docker-compose
Creating network "logtrace_default" with the default driver
Pulling collector (otel/opentelemetry-collector:latest)...
latest: Pulling from otel/opentelemetry-collector
f6cc2adcc462: Pull complete
08f620cbce51: Pull complete
...
```

{% capture question %}
Did you know you can check out stuff with [svn][] from [GitHub][]?
{% endcapture %}

{% include question.html content=question %}

### Podman

And if you prefer [Podman][], there are some [make][] targets waiting:

###### **Shell**:
```shell
$ svn export https://github.com/unexist/showcase-logging-tracing-quarkus/trunk/podman
A    podman
A    podman/Makefile
A    podman/collector
A    podman/collector/Dockerfile
A    podman/collector/otel-collector-config.yaml
A    podman/fluentd
A    podman/fluentd/Dockerfile
A    podman/fluentd/fluent.conf
Exported revision 107.

$ make -f podman/Makefile pd-init
Downloading VM image: fedora-coreos-35.20220131.2.0-qemu.x86_64.qcow2.xz: done
Extracting compressed file
Image resized.
INFO[0000] waiting for clients...
INFO[0000] listening tcp://127.0.0.1:7777
INFO[0000] new connection from  to /var/folders/fb/k_q6yq7s0qvf0q_z971rdsjh0000gq/T/podman/qemu_podman-machine-default.sock
Waiting for VM ...
...

$ make -f podman/Makefile pd-start
Trying to pull docker.elastic.co/elasticsearch/elasticsearch:7.16.0...
Getting image source signatures
Copying blob sha256:5759d6bc2a4c089280ffbe75f0acd4126366a66ecdf052708514560ec344eba1
Copying blob sha256:da847062c6f67740b8b3adadca2f705408f2ab96140dd19d41efeef880cde8e4
...
```

```
https://www.agile-academy.com/en/agile-dictionary/persona/
https://martinfowler.com/bliki/UbiquitousLanguage.html
https://egon.io
```