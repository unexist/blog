---
layout: post
title: Logging vs Tracing
date: %%%DATE%%%
author: Christoph Kappel
tags: tracing jaeger opentelemetry logging kibana elascticsearch fluentd gelf domainstory showcase
categories: observability showcase
toc: true
---
If you talk to developers about what they need to figure out what is happening in an application,
usually the single answer to this is logging or just logs. This can work pretty well for standalone
applications, but what about [distributed][] ones? Todays systems easily span across dozen of
services on different nodes and might have a quite complex call hierarchy.

In this post I want to demonstrate the difference between **logging** and **tracing** and that
needs a bit if explanation before we really can compare both. So in the first part we are covering
the foundation and talk about what both actually is. After that, I am going to present my really
convoluted example (to prove my point) and then we going to conclude our learnings.

Are you still with me? Great - let us move on to **logging**!

### Logging

#### What is a log?

A **log** is a timestamped event that happened at a particular time on a system. These logs can be
pure informational, like when a user sends a request to your service, but can also carry helpful
bits of information to figure out what exactly went wrong during troubleshooting. There are
different categories (or levels) for log messages like  **Info**, **Warn** or **Error**, which can
be used to filter the data and/or create monitoring alarms.

Separating good information from line noise can be quite a task and it is oftentimes difficult to
keep logs manageable, especially when aggregated from multiple services at a central place.

#### Structured logs

When we talk about logs, we are usually referring to unstructured text and it can become a
challenge to query them for something specific. An easy solution here is switch the format and use
something that is structured. The defacto standard is JSON and many logging libraries come with
integrated support.

Here is an example of a structured log entry:

###### **Structured log**:
```json
{
    "host": "C02FQ379MD6R",
    "short_message": "Created todo",
    "full_message": "Created todo",
    "level": 6,
    "facility": "jboss-logmanager",
    "todo": "dev.unexist.showcase.todo.domain.todo.Todo@151819bd",
    "LoggerName": "dev.unexist.showcase.todo.adapter.TodoResource",
    "SourceSimpleClassName": "TodoResource",
    "SourceClassName": "dev.unexist.showcase.todo.adapter.TodoResource",
    "Time": "2022-01-20 10:02:49,917",
    "Severity": "INFO",
    "Thread": "executor-thread-0",
    "SourceMethodName": "create",
    "@timestamp": "2022-01-20T09:02:49.917000055+00:00"
}
```

There is lots of meta information included by default and ranges from calling class, to the method
or the host and each piece of information can be used to fine-tune your search results in e.g.
 [Kibana][]:

![image](/assets/images/20220115-kibana_search.png)

#### More meta information

If you have a closer look at our example, the message `Created todo` is no help at all without some
kind of context like the working object it created or its attributes at least. One way is to just
append it to the log message itself, but this kind of beats the idea to have something structured
and you are losing on of the advantages to be able create decent queries for it.

Most logging libraries support the usage of [Mapped Diagnostic Context][] (or **MDC**) to provide
exactly that. With it, you can add information to the context and it is included in the next log
message for this thread until you remove it again:

###### **Logging.java**:
```java
/* Manual MDC handling */
MDC.put("foo", "bar");
LOGGER.info("Created todo");
MDC.remove("foo");

/* try-with-resources block */
try (MDC.MDCCloseable closable = MDC.putCloseable("foo", "bar")) {
    LOGGER.info("Created todo");
}
```

Advanced logging libraries also provide helpers to add key-value pairs conveniently:

###### **Logging.java**:
```java
/* quarkus-logging-json () */
LOGGER.info("Created todo", kv("todo", todo), kv("foo", "bar"));

/* Logstash */
LOGGER.info("Created todo", keyValue("todo", todo), keyValue("foo", "bar"));

/* Echopraxia */
LOGGER.info("Created todo", fb -> List.of(fb.todo("todo", todo), fb.string("foo", "bar")));
```

The first two are probably easy to understand, the latter comes with the concept of
[field builders][] as formatter for your objects. If this sounds and looks interesting head over
to [Echopraxia][] and give it a spin.

Depending on the [logshipper][], it will pick up your additions to the [MDC][] and transfer it
to [Kibana][]:

###### **Structured log**:
```json
{
    "host": "C02FQ379MD6R",
    "short_message": "Created todo",
    "full_message": "Created todo",
    "level": 6,
    "facility": "jboss-logmanager",
    "todo": "dev.unexist.showcase.todo.domain.todo.Todo@151819bd",
    "LoggerName": "dev.unexist.showcase.todo.adapter.TodoResource",
    "SourceSimpleClassName": "TodoResource",
    "foo": "bar",
    "SourceClassName": "dev.unexist.showcase.todo.adapter.TodoResource",
    "Time": "2022-01-20 10:02:49,917",
    "Severity": "INFO",
    "Thread": "executor-thread-0",
    "SourceMethodName": "create",
    "@timestamp": "2022-01-20T09:02:49.917000055+00:00",
}
```

{% capture note %}
I didn't provide any fancy output format of the `Todo` object, but you still should get the point.
{% endcapture %}

{% include note.html content=note %}

### Tracing

### What is a trace?

A **trace** is a visualization of a request of its way through multiple services in a microservice
environment and can uniquely be identified by a **trace ID**.

[context propagation][] is
allowed it
It can uniquely be identified by **trace ID** and collects a new **span** When it is created a unique **trace ID**. It keeps this

id while it is passed via [context propagation][] from  On each
new step, a **span** is added to the **trace**.

These **spans** are the smallest unit in the world of distributed tracing and represent
any kind of workflow of your application like HTTP requests, calls of a database or even message
handling in [eventing][].

On creation, the **trace ID** is assigned and it, while it is passed via
[context propagation][] from one point to another in your landscape. On each step, a new [span][]
with a **span ID** is created and can additionally carry other useful bits of information like
timing, [tags][], a status or other attributes.

![image](/assets/images/20220115-jaeger_trace.png)

In the example above you can see a single trace in [Jaeger][], that consists of 20 spans, passed
three services and took 3.73s in total.

#### Tracing with OpenTelemetry

I originally started with [OpenTracing][] for this post, but [Quarkus][] finally made the switch
to  [OpenTelemetry][] and I had to start from scratch. Poor me, but let us focus on
[OpenTelemetry][] then.

[Quarkus][] or rather [Smallrye][] comes with some nice defaults: All it takes is to add the
necessary dependency and it happily creates a new trace for every incoming or outgoing HTTP
request:



###### **TodoService.java**:
```java
@WithSpan("Create todo") // <1>
public Optional<Todo> create(TodoBase base) {
    Todo todo = new Todo(base);

    todo.setId(UUID.randomUUID().toString());

    await().between(Duration.ofSeconds(1), Duration.ofSeconds(10));

    Span.current()
            .addEvent("Added id to todo", Attributes.of(
                    AttributeKey.stringKey("id"), todo.getId())) // <2>
            .setStatus(StatusCode.OK); // <3>

    return Optional.of(todo);
}
```

**<1>** Create a new span \
**<2>** Add a logging event to the current span \
**<3>** Set status code of the current span






## Tell a Domainstory

In this post I want to demonstrate the difference between [logging][] and [tracing][], so we are
going to use a totally contrived example with needless complexity, just to prove my point. I
hadn't had time to start with a post about [Domain Storytelling][], but I think this format is
well-suited to give you an overview about what is supposed to happen:

![image](/assets/images/20220115-overview.png)

That is probably lots of information to the untrained eye, so let me break this down a bit.

### Get the whole story

One of the main drivers of [Domain Storytelling][] is to convey information step-by-step in
complete sentences. Each step is one action item of the story and normally just covers one
specific path - the happy path here.

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



#### Send logs to Kibana

###### **pom.xml**:
```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-logging-gelf</artifactId>
</dependency>
```

###### **application.properties**:
```property
quarkus.log.handler.gelf.enabled=true
#quarkus.log.handler.gelf.host=localhost
quarkus.log.handler.gelf.host=tcp:localhost
quarkus.log.handler.gelf.port=12201
quarkus.log.handler.gelf.include-full-mdc=true
```



## Logging vs Tracing

Now that we have a common understanding what this example is all about, let us get started with
our comparison of [logging][] and [tracing][].

| Logging ([Kibana][])                        | Tracing ([Jaeger][])                         |
|----------------------------------------------|----------------------------------------------|
| ![image](/assets/images/20220115-kibana.png) | ![image](/assets/images/20220115-jaeger.png)

## Conclusion

[Logging][] and [Tracing][] aren't mutual exclusive..

All of the examples can be found here:

<https://github.com/unexist/showcase-logging-vs-tracing-quarkus>


https://github.com/unexist/showcase-logging-tracing-quarkus/blob/master/docs/todo.dst
https://egon.io
https://github.com/tersesystems/echopraxia
https://github.com/quarkiverse/quarkus-logging-json
https://www.innoq.com/en/blog/structured-logging/
https://github.com/quarkusio/quarkus/issues/18228
https://logback.qos.ch/manual/mdc.html
https://quarkus.io/guides/centralized-log-management
https://opentelemetry.lightstep.com/core-concepts/context-propagation/
https://opentelemetry.lightstep.com/spans/