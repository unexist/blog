---
layout: post
title: One month of Podman
date: %%%DATE%%%
author: Christoph Kappel
tags: showcase
tags: tools docker podman jaeger quarkus opentracing opentelemetry gelf fluentd showcase
categories: tech showcase
toc: true
---
In my previous post [Migrating to Poadman]({% post_url 2021-12-01-migrating-to-podman %}) you
basically accompanied me on my migration from a [docker-compose][] file to a more CLI-based approach
with [Podman][]. I am still working on the **logging-vs-tracing** showcase, but there were a few
surprises and I just wanted to write a follow-up instead of just modifying my original post.

## Container ports

I originally started with [OpenTracing][], but while I was trying to figure everything out the
[Quarkus][] project finally made the switch to [OpenTelemetry][] and I had to start again. I am
going to explain **how** in my next post, so let us just accept the fact that [OpenTelemetry][]
needs another [collector][] which has to be added to my setup.

Adding another container is no problem, but when I tried to fire it up I found this in the logs:

###### **Log**:
```log
Error: cannot setup pipelines: cannot start receivers: listen udp :6832: bind: address already in use
```

The apparent problem here is that both the [jaeger-collector][] and the [otel-collector][] run on
the same port. To my surprise, there is no network separation of the containers inside of a
[pod][] (by default), but after some headaches to be expected. When you publish a port it also
just works on [pod][]-level for **rootless**.

## Networking between pods

I spent some hours trying to figure out, if I can just disable this port either for the
[jaeger-collector][] or the [otel-collector][], but to no avail. Desperate as I was, I just moved
both collectors to different [pods][] and considered it done.

This was, when I discovered how my networking really worked: Although I can access the published
ports from my host machine, the application inside of the container inside of a [pod][] cannot.

Possible solutions that I came up with:

1. Switch the [pod][] network from [bridge][] to [sirp4netns][] mode and find solutions for all
newly introduced problems.
2. Move from [jaeger-all-in-one][] to the standalone versions of each component. (There is also
[opentelemetry-all-in-one][] version, but according to [this][] post it has been discontinued.)
3. Start [Jaeger][] first and just hope it doesn't complain.

Yes, I went the obvious way and just started [Jaeger][] first, worked like a charm..

## No support for UDP

[Tracing][] finally running, I discoverd that my [Quarkus][] instances couldn't connect to
[Fluentd][] on port 12201 anymore:

###### **Log**:
```log
LogManager error of type GENERIC_FAILURE: Port localhost:12201 not reachable
```

The problem here is that I configured [Fluentd][] to expect [gelf][] messages there and absolutely
had no clue about the message format. I found this handy shell script as a gist, kudos to the
author:

<https://gist.github.com/gm3dmo/7721379>

With it, I could verify two things:

1. I couldn't reach [Fluentd][] from my host machine.
2. And inside of the container everything worked fine.

Some hours later I stumbled upon this:

<https://issueexplorer.com/issue/containers/podman-machine-cni/8>

This pretty much explained all my problems: Currently [gvproxy][] has no support for udp and just
ignores the udp flag altogether. My instances were expecting udp, all they got was tcp and this
ultimately failed.

The easiest solution here was to configure [gelf][] to run on tcp, which both the input plugin and
in the [gelf][] handler of [Quarkus][] support. I don't want to bore you with the troubles I had to
find the correct config option, so I will just point you to the source code:

<https://github.com/MerlinDMC/fluent-plugin-input-gelf/blob/master/lib/fluent/plugin/in_gelf.rb>

## Conclusion

I had some problems getting warm with[Podman][], but since I've sorted this out it works like a
charm. I created even more scripts to make the usage for me easier - with the help of [fzf][], ofc.

I know I don't have to remind you, but my logging-vs-tracing showcase can still be found here:

<https://github.com/unexist/showcase-logtraceability-quarkus>
