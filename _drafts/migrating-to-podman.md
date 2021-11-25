---
layout: post
title: migrating to podman
date: 2021-11-20 12:51 +0100
author: Christoph Kappel
tags: tools docker podman macos howcase
categories: tech showcase
toc: true
---
[Docker][] is among the best-known container runtimes and probably only a few people (and sadly
that didn't include me) considered some of the [other available options][]. When [Kubernetes][]
announced they want to phase-out the [Dockershim][], there was a bit of an uproar, but it probably
took the recent [license change][] for people to really want to move on.

I see these signals as a great opportunity for other runtimes to get more attention and also think
the time is right to give them a try. One of them, [Podman][] has been on my list for a pretty long
time, but due to their limitation to run on Linux systems only, this poor macOS user never had the
chance to really look into it. Gladly, they've found a workaround with [Qemu][] - so let us give it
a spin now.

## Podman

### Installation

[Podman][5] comes with a pretty good [install guide][10], but basically boils down to:

###### **Shell**:
```bash
$ brew install podman
```

And once the installation is complete we can create and start our machine like this:

###### **Shell**:
```bash
$ podman machine init --memory=8192 --cpus=2
$ podman machine start
```

### Is there an UI?

If you come from [Docker for Desktop][1] you will probably wonder if there is some kind of UI.

[podman-macos][14] deals with all the nooks and crannies and provides some basic interface to start
and stop the machine and also a limited control over running containers. It works perfectly, but
one of my personal problems with [Docker for Desktop][] is I am so used to rely on the UI, I never
got fluent in using it from the CLI, which actually hurts my heart as a long time console user.

### Can I compose?

Although I've made the decision to run all commands via CLI in this post, there still is the open
question if there is something like [docker-compose][7] for [Podman][].

[podman-compose][13] can help to translate your [docker-compose][7] file to the commands required
for [Podman][5], but has some drawbacks:

1. It directly runs all of them and mixes the outputs.
2. During my tests it didn't expose any of the container ports.
3. Why the heck are people still using absolute paths in a shebang? Please use **env**.

Unfortunately there isn't support for [Podman][] in [lazydocker][] yet:

<https://github.com/jesseduffield/lazydocker/issues/4>

Since [Podman][] does some things a bit differently than [Docker][], let us sort this out before we
go on.

### What about networking?

Naturally, containers can be started with different privileges and this greatly impacts how
networking is handled internally in default configuration:

- In **rootfull** mode (_run as root_), a network bridge connects the containers in a virtual
network, so they can access each other and the outside network (like the internet) via NAT. This
also allows to bind container ports to privileged host ports. (<1024)
- In **rootless** mode (_run as user_), a tap device is created to connect the container's network
with the usermode TCP/IP-stack, which unfortunately completely isolates containers from each other.
The only way to access others containers is via host ports.

For all practical means, both modes behave quite similar for a standalone container. If you require
a group of them, which must be able to connect to each other, it gets complicated. To ease this,
[Podman][] allows the creation of a [pod][].

### What is a pod?

The concept of a [pod][] was originally introduced within [Kubernetes][]:

> Pods are the smallest, most basic deployable objects in Kubernetes. A Pod represents a single
instance of a running process in your cluster. Pods contain one or more containers, such as Docker
containers. When a Pod runs multiple containers, the containers are managed as a single entity and
share the Pod's resources.
<cite>https://cloud.google.com/kubernetes-engine/docs/concepts/pod</cite>

So generally speaking, a [pod][] is a group of containers, that share the same network, process id
and also the ipc namespaces and this is true for both [Podman][] and [Kubernetes][].

###### **Shell**:
```bash
$ podman pod create -n observ
```

Due to this conceptual resemblance it shoudln't surprise anyone, that we can easily convert a
[Podman][5] pod to something, that can be deployed directly to [Kubernetes][3]:

###### **Shell**:
```bash
$ podman generate kube my-pod >> my-pod.yaml
```

### How to add containers manually?

Like the previous commands, adding containers to our new pod is also really easy:

###### **Shell**:
```bash
$ podman run -it --pod=observ busybox
```

Equipped with this we should be able to start our services now.

## How do we start?

I am currently working on a showcase for logging vs tracing, which needs a bit of infrastructure
components, so this sounds like a nice exercise: In this post we are going to migrate from
[Docker][2] and [docker-compose][7] to something that works properly with [Podman][5].

And for completeness, here is the [docker-compose][7] file upfront:

<https://github.com/unexist/showcase-observability-quarkus/blob/master/docker/docker-compose.yaml>

## Services

In this section we are going to create each service from my [docker-compose][7] file and start
it via [Podman][5]. Since we are doing it manually, we ignore the dependencies between the services
and just start everything in order.

### jaeger

###### **docker-compose.yaml**:
```yaml
# Install jaeger
jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
        - "6831:6831/udp"
        - "16686:16686"
```

The first service is pretty easy, the only new thing is how to expose ports. This can be done with
`-p` or with the long version `--publish`:


###### **Shell**:
```bash
$ podman run -it --pod=observ busybox
```

### Elastic

###### **docker-compose.yaml**:
```yaml
# Install elastic
elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch-oss:6.8.2
    ports:
        - "9200:9200"
        - "9300:9300"
    environment:
        ES_JAVA_OPTS: "-Xms512m -Xmx512m"
```

```log
ERROR: [1] bootstrap checks failed
[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

```bash
$ podman run -it --name elastic --pod=observ -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
```

### Fluent

###### **docker-compose.yaml**:
```yaml
# Install fluentd
fluentd:
    build: .
    ports:
        - "12201:12201/udp"
    volumes:
        - source: ./fluentd
        target: /fluentd/etc
        type: bind
    depends_on:
        - elasticsearch
```

### Kibana

###### **docker-compose.yaml**:
```yaml
# Kibana
kibana:
    image: docker.elastic.co/kibana/kibana-oss:6.8.2
    ports:
        - "5601:5601"
    depends_on:
        - elasticsearch
```

### Redpanda

###### **docker-compose.yaml**:
```yaml
# Install redpanda
redpanda:
    container_name: redpanda
    image: vectorized/redpanda
    hostname: redpanda
    ports:
        - "9092:9092"
```

## Conclusion

```log
https://www.docker.com/resources/what-container
https://www.capitalone.com/tech/cloud/container-runtime/
https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods
https://www.docker.com/blog/updating-product-subscriptions/
https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users#how_does_docker_work_
https://www.redhat.com/sysadmin/compose-podman-pods
https://podman.io/getting-started/installation
https://github.com/containers/podman-compose
https://github.com/heyvito/podman-macos
https://marcusnoble.co.uk/2021-09-01-migrating-from-docker-to-podman/
https://github.com/containers/podman/blob/main/docs/tutorials/basic_networking.md
https://kubernetes.io/blog/2020/12/02/dont-panic-kubernetes-and-docker/
```