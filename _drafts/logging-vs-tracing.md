---
layout: post
title: Logging vs Tracing
date: %%%DATE%%%
author: Christoph Kappel
tags: tracing jaeger opentelemetry logging kibana elascticsearch fluentd gelf showcase
categories: observability showcase
toc: true
---
[Migrating to Podman]({% post_url 2021-12-01-migrating-to-podman %})

Podman Port
Jaeger vs Collector Port 6832

```log
Error: cannot setup pipelines: cannot start receivers: listen udp :6832: bind: address already in use
```

```log
LogManager error of type GENERIC_FAILURE: Port localhost:12201 not reachable
```

gvproxy cannot port forward UDP until Podman v4

https://issueexplorer.com/issue/containers/podman-machine-cni/8


Fluent, gelf, TCP: protocol_type

https://github.com/MerlinDMC/fluent-plugin-input-gelf/blob/master/lib/fluent/plugin/in_gelf.rb

Opentracing vs Opentelemetry
Quarkus Update