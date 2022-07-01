---
layout: post
title: One month of Podman
date: 2021-12-28 22:45 +0100
last_modified_at: 2022-01-01 15:00 +0100
author: Christoph Kappel
tags: tools docker podman jaeger quarkus opentracing opentelemetry gelf fluentd showcase
categories: tech showcase
toc: true
---
In my previous post [Migrating to Poadman]({% post_url 2021-12-01-migrating-to-podman %}) you
basically accompanied me on my migration from a [docker-compose][10] file to a more CLI-based
approach with [Podman][5]. I am still working on the **logging-vs-tracing** showcase, but there
were a few surprises and I just wanted to write a follow-up instead of just modifying my original
post.

## Container ports

I originally started with [OpenTracing][4], but while I was trying to figure everything out the
[Quarkus][6] project finally made the switch to [OpenTelemetry][3] and I had to start again. I am
going to explain **how** in my next post, so let us just accept the fact that [OpenTelemetry][3]
needs another [collector][9] which has to be added to my setup.

Adding another container is no problem, but when I tried to fire it up I found this in the logs:

###### **Log**:
```log
Error: cannot setup pipelines: cannot start receivers: listen udp :6832: bind: address already in
use
```

The apparent problem here is that both the [jaeger-collector][15] and the [otel-collector][17] run
on the same port. To my surprise, there is no network separation of the containers inside of a
[pod][18] (by default), but after some headaches to be expected. When you publish a port it also
just works on [pod][18]-level for **rootless**.

## Networking between pods

I spent some hours trying to figure out, if I can just disable this port either for the
[jaeger-collector][15] or the [otel-collector][17], but to no avail. Desperate as I was, I just
moved both collectors to different [pod][19] and considered it done.

This was, when I discovered how my networking really worked: Although I can access the published
ports from my host machine, the application inside of the container inside of a [pod][18] cannot.

Possible solutions that I came up with:

1. Switch the [pod][18] network from [bridge][8] to [sirp4netns][19] mode and find solutions for
all newly introduced problems.
2. Move from [jaeger-all-in-one][14] to the standalone versions of each component. (There is also
[opentelemetry-all-in-one][16] version, but according to [this][20] post it has been discontinued.)
3. Start [Jaeger][2] first and just hope it doesn't complain.

Yes, I went the obvious way and just started [Jaeger][2] first, worked like a charm..

## No support for UDP

[Tracing][7] finally running, I discoverd that my [Quarkus][6] instances couldn't connect to
[Fluentd][1] on port 12201 anymore:

###### **Log**:
```log
LogManager error of type GENERIC_FAILURE: Port localhost:12201 not reachable
```

The problem here is that I configured [Fluentd][1] to expect [gelf][12] messages there and
absolutely had no clue about the message format. I found this handy shell script as a gist, kudos
to the author:

<https://gist.github.com/gm3dmo/7721379>

With it, I could verify two things:

1. I couldn't reach [Fluentd][1] from my host machine.
2. And inside of the container everything worked fine.

Some hours later I stumbled upon this:

<https://issueexplorer.com/issue/containers/podman-machine-cni/8>

This pretty much explained all my problems: Currently [gvproxy][13] has no support for udp and just
ignores the udp flag altogether. My instances were expecting udp, all they got was tcp and this
ultimately failed.

The easiest solution here was to configure [gelf][12] to run on tcp, which both the input plugin
and in the [gelf][12] handler of [Quarkus][6] support. I don't want to bore you with the troubles
I had to find the correct config option, so I will just point you to the source code:

<https://github.com/MerlinDMC/fluent-plugin-input-gelf/blob/master/lib/fluent/plugin/in_gelf.rb>

## Conclusion

I had some problems getting warm with[Podman][5], but since I've sorted this out it works like a
charm. I created even more scripts to make the usage for me easier - with the help of [fzf][11],
ofc.

I know I don't have to remind you, but my logging-vs-tracing showcase can still be found here:

<https://github.com/unexist/showcase-logging-vs-tracing-quarkus>

[1]: https://www.fluentd.org/
[2]: https://www.jaegertracing.io/
[3]: https://opentelemetry.io/
[4]: https://opentracing.io/
[5]: https://podman.io/
[6]: https://quarkus.io/
[7]: https://en.wikipedia.org/wiki/Tracing_(software)
[8]: https://podman.io/getting-started/network
[9]: https://www.jaegertracing.io/docs/1.29/deployment/#collector
[10]: https://docs.docker.com/compose/
[11]: https://github.com/junegunn/fzf
[12]: https://www.graylog.org/features/gelf
[13]: https://pkg.go.dev/github.com/containers/gvisor-tap-vsock/cmd/gvproxy
[14]: https://hub.docker.com/r/jaegertracing/all-in-one
[15]: https://www.jaegertracing.io/docs/1.29/deployment/#collector
[16]: https://hub.docker.com/r/jaegertracing/opentelemetry-all-in-one/
[17]: https://github.com/open-telemetry/opentelemetry-collector
[18]: https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods
[19]: https://github.com/rootless-containers/slirp4netns
[20]: https://github.com/open-telemetry/opentelemetry-collector/discussions/2558