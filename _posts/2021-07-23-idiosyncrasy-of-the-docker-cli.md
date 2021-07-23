---
layout: post
title: Idiosyncrasy of the Docker CLI
date: 2021-07-23 10:53 +0200
tags: tools docker cli quarkus kafka redpanda
categories: tech
---
Although I use [Docker][1] on a daily basis, I never really got into its CLI. Most of the time I am
just baffled how complex it is to get really simple things done.

Just to set up the stage (I plan on writing a detailed post about [Redpanda][3]):

During my experiments with the latest [Quarkus][2] version, I stumbled upon a faster replacement
for [Kafka][5], which is either used as a default [devservice][4] now or some default of
[Kogito][6].

A [devservices][4] you might be wondering? Without going much into detail, it is basically an
integration of  [Testcontainers][7] to start required infrastructure services like a database for
testing in [Docker][1]. [Devservices][4] also take care of the config, so all the required mapping
is set automatically.

To configure [Redpanda][3], I need to know the exposed port to connect to and the
[Testcontainers][7] integration prints it dutifully to the log though:

#### **Log**:
```log
2021-07-23 07:48:44,130 INFO  [io.qua.kaf.cli.dep.DevServicesKafkaProcessor] (build-38) Dev Services for Kafka started. Start applications that need to use the same Kafka broker using -Dkafka.bootstrap.servers=PLAINTEXT://localhost:55002
```

This is still no option for custom scripts or in any way convenient.

## Docker CLI

[Docker][1] comes with a CLI as you probably know. After some digging into and a pinch of despair,
mapping of image name to the actual container is quite complicated. For my taste it takes way too
many calls to different shell tools, which probably is not portable, but it can be done with
[port][8] and [inspect][9]:
 
#### **Shell**:
```shell
$ docker port $(docker ps | grep redpanda | awk '{print $1}') | grep -m 1 9092 | cut -d ':' -f 2
```

Another thing I probably just lack experience with, is the format string. I am quite sure
this is just awesome for any seasoned [Go][10] developer and it is basically everywhere from there
starting with supporting tools like [Helm][11] or the foundation of the cloud itself,
[Kubernetes][12].

So if the next example is pretty straight forward to you have fun with it, I am in a corner reading
specs:

#### **Shell**:
```shell
{% raw %}
docker inspect --format='{{(index (index .NetworkSettings.Ports "9092/tcp") 0).HostPort}}' $(docker ps --format "{{.ID}}" --filter="ancestor=vectorized/redpanda:v21.5.5")
{% endraw %}
```

[1]: https://docker.com
[2]: https://quarkus.io
[3]: https://github.com/vectorizedio/redpanda
[4]: https://quarkus.io/blog/quarkus-1-13-0-final-released/
[5]: https://kafka.apache.org/
[6]: https://kogito.kie.org/
[7]: https://www.testcontainers.org/
[8]: https://docs.docker.com/engine/reference/commandline/inspect/
[9]: https://docs.docker.com/engine/reference/commandline/port/
[10]: https://golang.org/
[11]: https://helm.sh/
[12]: https://kubernetes.io/