---
layout: post
title: Migrating to Podman
date: 2021-12-01 19:00 +0100
author: Christoph Kappel
tags: tools docker podman macos kibana elastic fluent jaeger showcase
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

I am currently working on a showcase for logging vs tracing, which needs a bit of infrastructure
components, so this sounds like a nice exercise: In this post we are going to migrate from
[Docker][2] and [docker-compose][7] to something that works properly with [Podman][5].

And for completeness, here is the [docker-compose][7] file upfront:

<https://github.com/unexist/showcase-observability-quarkus/blob/master/docker/docker-compose.yaml>

## Podman

Before we start with the actual infrastructure services, let us talk a bit about [Podman][] and
cover the base installation and also some things that are good to know from the start.

### Installation

[Podman][5] comes with a pretty good [install guide][10], the essential part for us is:

###### **Shell**:
```shell
$ brew install podman
```

Right after the installation is complete we need to init and start our new machine:

###### **Shell**:
```shell
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

Although I've made the decision to run all commands in this post via CLI, there still is the open
question if there is something like [docker-compose][7] for [Podman][].

[podman-compose][13] can help to translate your [docker-compose][7] file to the commands required
for [Podman][5], but has some drawbacks:

1. It directly runs all of them and mixes the outputs.
2. It starts all containers in a new pod.
3. Ports of the container aren't properly exposed to the host.
4. And why the heck are people still using absolute paths in a shebang? Please use **env**.
5. The output is quite messy, if you are used to something like [lazydocker][].

Unfortunately there isn't support for [Podman][] in [lazydocker][] yet:

<https://github.com/jesseduffield/lazydocker/issues/4>

### What about networking?

Naturally, containers can be started with different privileges and this greatly impacts how
networking is handled internally in default configuration:

- In **rootfull** mode (_run as root_), a network bridge connects the containers in a virtual
network, so they can access each other and the outside network (like the internet) via NAT. This
also allows to bind container ports to privileged host ports. (<1024)
- In **rootless** mode (_run as user_), a tap device is created to connect the container's network
with the usermode TCP/IP-stack, which unfortunately completely **isolates** containers from each other.
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

Due to this conceptual resemblance it shoudln't surprise anyone, that we can easily convert a
[Podman][5] pod to something, that can be deployed directly to [Kubernetes][3]:

###### **Shell**:
```shell
$ podman generate kube my-pod >> my-pod.yaml
```

### How can I start a container?

If you need to start a single container either **rootfull** or **rootless** should work, so let us
focus on examples with and without a [pod][].

#### Rootless without a pod

###### **Shell**:
```shell
$ podman run -dt -p 8080:80 nginx
21ee82cae8b8e0e2744426c3a2f57d7274779b71370e242532e26d3e301124ca
```

Once the container is running you can reach it with curl:

```shell
$ curl -s localhost:8080 | htmlq --text h1
Welcome to nginx!
```

#### Rootless within a pod

Let us do the same again, but this time within a [pod][]. The first thing we have to do is to
create the actual [pod][]:

###### **Shell**:
```shell
$ podman pod create -n mypod -p 8080:80
41983bfdf2e1c13d209cf9d114abe6dc298fffc24b7385d353edabbbc9890792
```

This looks good, let us see what we've got:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Ports}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                 STATUS      PORTS                 NAMES               PODNAME
67b89dbd6e21  k8s.gcr.io/pause:3.5  Created     0.0.0.0:8080->80/tcp  b6548bd64e31-infra  mypod
```

Noteworthy here is we need to publish the ports on [pod][]-level and that [Podman][] creates an
[infrastructure container][] for us.

###### **Shell**:
```shell
$ podman run -dt --pod mypod nginx
e2182dec80aa1fb42a06a01337fe86e951b13d89f9b600c50b39678d25a24301
```

**Hint**: There is handy shortcut to directly start a container in a new [pod][]:

###### **Shell**:
```shell
$ podman run -dt --pod new:mypod -p 8080:80 nginx
309d7f33bf472d790a13cc1a1cc7fff432d026e4c26c3844731b5c448b1b100a
```

In a previous section about [networking](#what-about-networking), I've mentioned that containers
are isolated in this mode, here you can see it in action:

###### **Shell**:
```shell
$ curl localhost:8080
curl: (7) Failed to connect to localhost port 8080: Connection refused
```

This can be avoided by creating a new network or by just using the **bridge**:

###### **Shell**:
```shell
$ podman run -dt --pod new:mypod -p 8080:80 --network bridge nginx
54d6d488edad06477286e579fd255981761e5881b0d9a5eda1d5d7a14c016559
```

And just for the sake of completeness:

###### **Shell**:
```shell
$ curl -s localhost:8080 | htmlq --text h1
Welcome to nginx!
```

### How can I build a container?

Building container is also piece of cake. [Podman][] uses [buildah][] (or rather code from it) to
actually build the container, which is better explained [here][]. The interesting part for us is
that [Dockerfile][] is also supported and heads up to a quick and pointless example:

###### **Dockerfile**:
```Dockerfile
FROM nginx
```

###### **Shell**:
```shell
$ podman build --format docker -t mynginx .
STEP 1/1: FROM nginx
COMMIT mynginx
--> ea335eea17a
Successfully tagged localhost/mynginx:latest
Successfully tagged docker.io/library/nginx:latest
ea335eea17ab984571cd4a3bcf90a0413773b559c75ef4cda07d0ce952b00291
```

Equipped with this we should be able to start our services now.

## Services

In this section we are going to create each service from my [docker-compose][7] file and start
it via [Podman][5]. Since we are doing it manually, we ignore the dependencies between the services
and just start everything in correct order.

### Create a pod

No surprises here: We need a new [pod][], which also does the port handling on our bridge:

###### **Shell**:
```shell
$ podman pod create -n observ --network bridge -p 6831:6831/udp -p 16686:16686 \
		-p 9200:9200 -p 9300:9300 -p 12201:12201/udp -p 5601:5601 -p 9092:9092
ee627e6718c19e707eb03c97b5cf86e8280c91cce9b031fea000ff180fac3c28
```

A quick check if everything is well:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                                                    STATUS                  NAMES               PODNAME
443c40c601ee  k8s.gcr.io/pause:3.5                                     Up 3 days ago           ee627e6718c1-infra  observ
```

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

This is going to be easy:

###### **Shell**:
```shell
$ podman run -dit --name jaeger --pod=observ jaegertracing/all-in-one:latest
7f5a083ece1ee60e9d8b394bf25bd361aa98afa987a6840f0d5b2b5929b44b72
```

Checking time:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                                                    STATUS                  NAMES               PODNAME
443c40c601ee  k8s.gcr.io/pause:3.5                                     Up 3 days ago           ee627e6718c1-infra  observ
7f5a083ece1e  docker.io/jaegertracing/all-in-one:latest                Up 3 days ago           jaeger              observ
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

Besides the [environment][] there is also no magic involved:

###### **Shell**:
```shell
$ podman run -dit --name elastic --pod=observ -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
    docker.elastic.co/elasticsearch/elasticsearch:7.14.2
2d81acbf527a3f2c26b4c66133b4826c460f719124d2ff1d71005127994c77a7
```

Checking time:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                                                 STATUS                  NAMES               PODNAME
443c40c601ee  k8s.gcr.io/pause:3.5                                  Up 3 days ago           ee627e6718c1-infra  observ
7f5a083ece1e  docker.io/jaegertracing/all-in-one:latest             Up 3 days ago           jaeger              observ
2d81acbf527a  docker.elastic.co/elasticsearch/elasticsearch:7.14.2  Exited (78) 3 days ago  elastic             observ
```

Something obviously went wrong. Unfortunate, but let us check what is wrong here:

###### **Shell**:
```shell
$ podman logs 2d81acbf527a | grep -A 2 ERROR
ERROR: [1] bootstrap checks failed

[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

Looks like we have some problems within [Qemu][], that didn't happen in [Docker][]. The problem is
well explained here - including a solution:

<https://stackoverflow.com/questions/51445846/elasticsearch-max-virtual-memory-areas-vm-max-map-count-65530-is-too-low-inc>

Even easier than dealing with `systcl` inside of a container, let us just bump to the current
version of [elasticsearch][], which seems to ignore this error altogether:

###### **Shell**:
```shell
$ podman rm 2d81acbf527a
2d81acbf527a
$ podman run -it --name elastic --pod=observ -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
    -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.14.2
847f303ffa7562778ea8b15fb83f8a6f6beec949af78edfc31f060a1cb50469b
```

Checking time:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                                                 STATUS         NAMES               PODNAME
443c40c601ee  k8s.gcr.io/pause:3.5                                  Up 3 days ago  ee627e6718c1-infra  observ
7f5a083ece1e  docker.io/jaegertracing/all-in-one:latest             Up 3 days ago  jaeger              observ
847f303ffa75  docker.elastic.co/elasticsearch/elasticsearch:7.14.2  Up 3 days ago  elastic             observ
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

Next on our list is [fluent][]. For this service we need to mount and bind a host path into the
running container. Unfortunately, this is no easy task on macOS and there is a pending issue:

<https://github.com/containers/podman/issues/8016>

Alas, we don't need to be able to change the config on-the-fly, copying the config directly into
the container also does the trick here. So we are going to change the [Dockerfile][] from my
project a bit here:


###### **Dockerfile**:
```Dockerfile
FROM fluent/fluentd:v1.14-debian-1

USER root

COPY ./fluentd/fluent.conf /fluentd/etc/fluent.conf

RUN ["gem", "install", "fluent-plugin-elasticsearch"]
RUN ["gem", "install", "fluent-plugin-input-gelf"]

USER fluent
```

###### **Shell**:
```shell
$ cd docker
$ podman build --format docker -t fluent .
STEP 1/6: FROM fluent/fluentd:v1.14-debian-1
STEP 2/6: USER root
STEP 3/6: COPY ./fluentd/fluent.conf /fluent/etc/fluent.conf
STEP 4/6: RUN ["gem", "install", "fluent-plugin-elasticsearch"]
STEP 5/6: RUN ["gem", "install", "fluent-plugin-input-gelf"]
STEP 6/6: USER fluent
..
Successfully tagged localhost/fluent:latest
215d4b1979f362ec4ce38c4ef57da8e16c3261d7060f07ec403e2d86941c6c61
```

And after that we just need to start the container:

###### **Shell**:
```shell
$ podman run -dit --name fluent --pod=observ fluent
a76a5ecb32efb2ef5d22447d1cacce369ef6639afaadd3a8f41b1b6653c01852
```

Checking time again:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                                                 STATUS         NAMES               PODNAME
443c40c601ee  k8s.gcr.io/pause:3.5                                  Up 3 days ago  ee627e6718c1-infra  observ
7f5a083ece1e  docker.io/jaegertracing/all-in-one:latest             Up 3 days ago  jaeger              observ
847f303ffa75  docker.elastic.co/elasticsearch/elasticsearch:7.14.2  Up 3 days ago  elastic             observ
a76a5ecb32ef  localhost/fluent:latest                               Up 3 days ago  fluent              observ
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

I think you get it and know the drill. The only thing we need to take care of is the hostname of
[elasticsearch][], since networking works a bit different in [Podman][]:

###### **Shell**:
```shell
$ podman run -dit --name kibana --pod=observ -e "ELASTICSEARCH_HOSTS=http://localhost:9200" \
    docker.elastic.co/kibana/kibana-oss:7.10.2
cad125873b438efea4b549e51edc00981bf88bb3ed78c8bdf54aecb43fba64d8
```

More checking time:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                                                 STATUS         NAMES               PODNAME
443c40c601ee  k8s.gcr.io/pause:3.5                                  Up 3 days ago  ee627e6718c1-infra  observ
7f5a083ece1e  docker.io/jaegertracing/all-in-one:latest             Up 3 days ago  jaeger              observ
847f303ffa75  docker.elastic.co/elasticsearch/elasticsearch:7.14.2  Up 3 days ago  elastic             observ
a76a5ecb32ef  localhost/fluent:latest                               Up 3 days ago  fluent              observ
cad125873b43  docker.elastic.co/kibana/kibana:7.14.2                Up 3 days ago  kibana              observ
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

One more - last time - promised:

###### **Shell**:
```shell
$ podman run -dit --name redpanda --pod=observ vectorized/redpanda
b728da318549cca15ddd0019eec1cddff4e3e388cacbc0dcc1f7ea38480c81fc
```

And final checking time:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                                                 STATUS         NAMES               PODNAME
443c40c601ee  k8s.gcr.io/pause:3.5                                  Up 3 days ago  ee627e6718c1-infra  observ
7f5a083ece1e  docker.io/jaegertracing/all-in-one:latest             Up 3 days ago  jaeger              observ
847f303ffa75  docker.elastic.co/elasticsearch/elasticsearch:7.14.2  Up 3 days ago  elastic             observ
a76a5ecb32ef  localhost/fluent:latest                               Up 3 days ago  fluent              observ
cad125873b43  docker.elastic.co/kibana/kibana:7.14.2                Up 3 days ago  kibana              observ
b728da318549  docker.io/vectorized/redpanda:latest                  Up 3 days ago  redpanda            observ
```

## Conclusion

[Podman][] is a nice replacement for [Docker][], but not every workflow and especially not every
[docker-compose][] file works out of the box. Network handling is quite different, but that might
just be true on macOS.

While writing this post I enjoyed playing with it, learning the commands and also the way this can
be scripted and added some handy aliases to my zsh file like this goodie:

###### **Shell**:
```shell
$ eval `podman ps -a | fzf --multi --tac --no-sort | cut -d ' ' -f1 | sed -nE "s#(.*)#-l \'podman logs -f \1\'#gp" | xargs -r -0 -n10 -d'\n' echo multitail -C`
```

This basically displays the running container via [fzf][], allows multiselect and displays logs of
the selected container in [multitail][].

I never did something like this with [Docker][], would have saved me quite some headaches I suppose.

The showcase of the logging vs tracing can be found here:

<https://github.com/unexist/showcase-observability-quarkus>

```log
https://www.docker.com/resources/what-container
https://www.capitalone.com/tech/cloud/container-runtime/
https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods
https://www.docker.com/blog/updating-product-subscriptions/
https://www.redhat.com/sysadmin/compose-podman-pods
https://podman.io/getting-started/installation
https://github.com/containers/podman-compose
https://github.com/heyvito/podman-macos
https://marcusnoble.co.uk/2021-09-01-migrating-from-docker-to-podman/
https://github.com/containers/podman/blob/main/docs/tutorials/basic_networking.md
https://kubernetes.io/blog/2020/12/02/dont-panic-kubernetes-and-docker/
https://docs.podman.io/en/latest/markdown/podman-run.1.html
https://docs.podman.io/en/latest/markdown/podman-build.1.html
https://developers.redhat.com/blog/2019/02/21/podman-and-buildah-for-docker-users
```