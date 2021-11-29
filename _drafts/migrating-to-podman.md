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

Noteworthy here is we need to publish the ports on pod-level and that [Podman][] creates an
[infrastructure container][] for us.

###### **Shell**`
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
    docker.elastic.co/elasticsearch/elasticsearch-oss:6.8.2
2d81acbf527a3f2c26b4c66133b4826c460f719124d2ff1d71005127994c77a7
```

Checking time:

###### **Shell**:
```shell
$ podman ps -a --pod --format "table {{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.PodName}}"
CONTAINER ID  IMAGE                                                    STATUS                  NAMES               PODNAME
443c40c601ee  k8s.gcr.io/pause:3.5                                     Up 3 days ago           ee627e6718c1-infra  observ
7f5a083ece1e  docker.io/jaegertracing/all-in-one:latest                Up 3 days ago           jaeger              observ
2d81acbf527a  docker.elastic.co/elasticsearch/elasticsearch-oss:6.8.2  Exited (78) 3 days ago  elastic             observ
```

Something obviously went wrong.  Unfortunate, but let us check what is wrong here:

###### **Shell**:
```shell
$ podman logs 2d81acbf527a | grep -A 2 ERROR
ERROR: [1] bootstrap checks failed

[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

Looks like we have some problems within [Qemu][], that didn't happen in [Docker][]. The problem is
well explained here - including a solution:

<https://stackoverflow.com/questions/51445846/elasticsearch-max-virtual-memory-areas-vm-max-map-count-65530-is-too-low-inc>

Even easier than dealing with `systcl` inside of a container, let us just move on to the current version of
[elasticsearch][], which seems to ignore this error altogether:

###### **Shell**:
```shell
$ podman run -it --name elastic --pod=observ -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
    docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
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
https://docs.podman.io/en/latest/markdown/podman-run.1.html
```