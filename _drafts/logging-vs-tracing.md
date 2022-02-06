---
layout: post
title: Logging vs Tracing
date: %%%DATE%%%
author: Christoph Kappel
tags: tracing jaeger opentelemetry logging kibana elasticsearch fluentd gelf domain-storytelling showcase
categories: observability showcase
toc: true
---
If you talk to developers about what they need to figure out what is happening in an application,
usually the single answer to this is logging or just logs.
This can work pretty well for standalone applications, but what about more complex or even
[distributed][] ones?

In this post I want to demonstrate the difference between **logging** and **tracing** and talk
why and when I would prefer one over the other.
So in the first part we are covering the basics and talk a bit about what both actually is.
After that, I am going to present my really convoluted example just to prove my point and based on
that we are going to do the actual comparison.

Are you still with me? Great - let us move on to **logging**!

### Logging

#### What is a log?

Generally speaking, a **log** is some kind of output of an event that happened on an application
on a specific system at a particular time.
During the daily business logs can be pure informational, like when a user sends a request to your
service, but when there is an application issue, they can deliver helpful bits of information
for troubleshooting.

One problem with log messages is the sheer amount of data that is generated every day, which makes
it quite difficult to keep track of them and to find something specific.
To keep them manageable, they are grouped into different categories (called levels) like **Info**,
**Warn** or **Error**, depending on their severity.
Theses log levels can be used to filter data and to create monitoring alarms.

Here is an example of a simple log message:

###### **Logging.java**:
```java
LOGGER.info("Created todo");
```

###### **Log**:
```log
2022-01-19 16:46:14,298 INFO  [dev.une.sho.tod.ada.TodoResource] (executor-thread-0) Created todo
```

Writing good log message can be difficult and there is usually lots of discussion what and
especially when to log something.
A good approach here is to consider the log as a kind of journal for your application and always
provide enough contextual information to be able to reproduce what has happened.
Useful information can be everything like request ID's, user ID's or other object identifiers.

#### Adding context

Knowing this and with a skeptical view at our previous example, there is an awful lack of any
contextual information and we really should fix that.
For single messages, this can be easily done by appending e.g. the object ID manually:

###### **Logging.java**:
```java
LOGGER.info("Created todo: id={}", todo.getId());
```

###### **Log**:
```log
2022-01-19 16:46:14,298 INFO  [dev.une.sho.tod.ada.TodoResource] (executor-thread-0) Created todo: id=8659a492-1b3b-42f6-b25c-3f542ab11562
```

This new version of our log message allows to search for a particular object ID and can also be
used to correlate different messages; but what if we have more than one message?

Doing this manually can be a labor intensive and error-prone task and a single deviation makes it
impossible to find this message:

###### **Logging.java**:
```java
LOGGER.info("Created todo: id ={}", todo.getId());
```

#### Mapped Diagnostic Context

Modern logging libraries support the usage of a [MDC][] to automate this e.g. via [filters][],
[interceptors][] or even [aspect-oriented programming][].
The [MDC][] allows to add information via static methods to a thread-based context and a properly
configured logger is able to pick it up and include in the next log messages until you remove it
again:

###### **Logging.java**`
```java
/* Manual MDC handling */
MDC.put("todo_id", todo.getId());
LOGGER.info("Created todo");
MDC.remove("todo_id");

/* try-with-resources block */
try (MDC.MDCCloseable closable = MDC.putCloseable("todo_id", toto.getId())) {
    LOGGER.info("Created todo");
}
```

Unfortunately, the default logger of [Quarkus][] requires further configuration to actually include
[MDC][] information:

###### **application.properies**:
```properties
quarkus.log.console.format=%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c{2.}] (%t) %X %s%e%n
```

But after this change the log dutifully includes our value:

###### **Log**:
```log
2022-01-19 16:46:14,298 INFO  [de.un.sh.to.ad.TodoResource] (executor-thread-0) {todo_id=8659a492-1b3b-42f6-b25c-3f542ab11562} Created todo
```

Adding all the parameters either manually or via [MDC][] allows to write better filter queries for
our values, but we are still using an unstructured format which cannot be parsed easily.

#### Structured logs

Switching to a structured format further improves the searchability and allows to include
additional meta information like the calling class or the host name and to add (business)
analytics.
The defacto standard for structured logs is [JSON][] and supported widely.

The [quarkus-logging-json][] extension adds this capability:

###### **Structured log**:
```json
{
  "timestamp": "2022-02-04T17:23:34.674+01:00",
  "sequence": 1987,
  "loggerClassName": "org.slf4j.impl.Slf4jLogger",
  "loggerName": "dev.unexist.showcase.todo.adapter.TodoResource",
  "level": "INFO",
  "message": "Created todo",
  "threadName": "executor-thread-0",
  "threadId": 104,
  "mdc": {
    "todo_id": "8659a492-1b3b-42f6-b25c-3f542ab11562"
  },
  "hostName": "c02fq379md6r",
  "processName": "todo-service-create-dev.jar",
  "processId": 97284
}
```

Advanced logging libraries also provide helpers to add key-value pairs conveniently to the
[MDC][]:

###### **Logging.java**:
```java
/* quarkus-logging-json */
LOGGER.info("Created todo", kv("todo_id", todo.getId()));

/* Logstash */
LOGGER.info("Created todo", keyValue("todo_id", todo.getId()));

/* Echopraxia */
LOGGER.info("Created todo", fb -> fb.onlyTodo("todo", todo));
```

The first two are probably easy to understand, the latter comes with the concept of
[field builders][] as formatter for your objects.
If this sounds interesting head over to [Echopraxia][] and give it a spin.

#### Central log aggregation

Another benefit if storing

###### **pom.xml**:
```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-logging-gelf</artifactId>
</dependency>
```

###### **application.properties**:
```properties
quarkus.log.handler.gelf.enabled=true
#quarkus.log.handler.gelf.host=localhost
quarkus.log.handler.gelf.host=tcp:localhost
quarkus.log.handler.gelf.port=12201
quarkus.log.handler.gelf.include-full-mdc=true
```

![image](/assets/images/20220115-kibana_search.png)

###### **Kibana**:
```json
{
    "host": "C02FQ379MD6R",
    "short_message": "Created todo",
    "full_message": "Created todo",
    "level": 6,
    "facility": "jboss-logmanager",
    "todo_id": "8659a492-1b3b-42f6-b25c-3f542ab11562",
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

### Tracing

### What is a trace?

A **trace** is a visualization of a request of its way in a microservice environment. When it is
created it gets an unique **trace ID** assigned and collects **spans** on every step it passes
through.

These **spans** are the smallest unit in the world of distributed tracing and represent
any kind of workflow of your application like HTTP requests, calls of a database or even message
handling in [eventing][].

[context propagation][] is
allowed it
It can uniquely be identified by **trace ID** and collects a new **span** When it is created a unique **trace ID**. It keeps this

id while it is passed via [context propagation][] from  On each
new step, a **span** is added to the **trace**.


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

## Example time

As I've mentioned earlier, I've prepared a really convoluted example for this post, so let my try
to explain what this is about.

### Tell a Domainstory

I hadn't had time to start with a post about [Domain Storytelling][], but I think this format is
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
https://quarkus.io/guides/logging
https://opentelemetry.lightstep.com/core-concepts/context-propagation/
https://opentelemetry.lightstep.com/spans/