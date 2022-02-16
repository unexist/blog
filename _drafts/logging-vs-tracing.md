---
layout: post
title: Logging vs Tracing
date: %%%DATE%%%
author: Christoph Kappel
tags: tracing jaeger opentelemetry logging kibana elasticsearch fluentd gelf showcase
categories: observability showcase
toc: true
---
If you talk to developers about what they need to figure out what is happening in an application,
usually the single answer to this is logging or just logs.
This can work pretty well for standalone applications, but what about more complex or even
[distributed][] ones?

In this post I want to demonstrate the difference between **logging** and **tracing** and talk
about why and when I prefer one over the other.
In the first part we are going to cover some basics first and talk about what both actually is and
then do the actual comparison in the second one.

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

If we consider our previous example, there is an awful lack of any context and we really should fix
that:

###### **Logging.java**:
```java
LOGGER.info("Created todo: id={}", todo.getId());
```

###### **Log**:
```log
2022-01-19 16:46:14,298 INFO  [dev.une.sho.tod.ada.TodoResource] (executor-thread-0) Created todo: id=8659a492-1b3b-42f6-b25c-3f542ab11562
```

Adding the object ID to the messages allows to search for a particular object and can also be used
to correlate different messages.
This works for single messages, but what if we have more than one message?

Doing this manually can be a labor intensive and error-prone task and a single deviation makes it
really difficult to find the message again:

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

###### **application.properties**:
```properties
quarkus.log.console.format=%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c{2.}] (%t) %X %s%e%n
```

After this change the log dutifully includes our value:

###### **Log**:
```log
2022-01-19 16:46:14,298 INFO  [de.un.sh.to.ad.TodoResource] (executor-thread-0) {todo_id=8659a492-1b3b-42f6-b25c-3f542ab11562} Created todo
```

Adding all the parameters either manually or via [MDC][] allows to write better filter queries for
our values, but we are still using an unstructured format which cannot be parsed easily.

#### Structured logs

Switching to a structured format further improves the *searchability* (is that even a word?) and
allows to include additional meta information like the calling class or the host name and to feed
it into (business) analytics.
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

More advanced logging libraries also provide helpers to add key-value pairs conveniently to the
[MDC][].
Here are few noteworthy examples:

###### **Logging.java**:
```java
/* quarkus-logging-json */
LOGGER.info("Created todo", kv("todo_id", todo.getId()));

/* Logstash */
LOGGER.info("Created todo", keyValue("todo_id", todo.getId()));

/* Echopraxia */
LOGGER.info("Created todo", fb -> fb.onlyTodo("todo", todo));
```

The first two are probably easy to understand, they just add the specific pair to the log.
The last one uses the concept of [field builders][] as formatter for your objects and with it you
can define which attributes are included.
If this sounds interesting head over to [Echopraxia][] and give it a spin.

#### Central logging

One of the goals of central logging is to have everything aggregated in one place and to provide
some kind of facility to create complex search queries.
There are hundreds of other posts about the different solutions, so let us focus on a simple
[EFK][] stack with [gelf][].

[Quarkus][] comes with an extension that does the bulk work for us, we just have to include it and
configure it for our setup:

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
#quarkus.log.handler.gelf.host=localhost <1>
quarkus.log.handler.gelf.host=tcp:localhost
quarkus.log.handler.gelf.port=12201
quarkus.log.handler.gelf.include-full-mdc=true
```

**<1>** Noteworthy here is [gelf][] uses UDP by default, so if you want to use [Podman][] please
keep in mind its [gvproxy][] doesn't support this yet.

It might take a bit of time due to caching and latency, but ones everything reached [Kibana][]
you should be able to see something like this:

![image](/assets/images/20220115-kibana_log.png)

Let us move on to **tracing** now.

### Tracing

### What is a trace?

A **trace** is a visualization of a request of its way through a complete microservice environment.
When it is created, it gets an unique **trace ID** assigned and collects **spans** on every step it
passes through.

These **spans** are the smallest unit in the world of distributed tracing and represent any kind
of workflow of your application like HTTP requests, calls of a database or even message handling
in [eventing][].
They include a **span ID**, specific timings and optionally other attributes, [events][] or
[status][].

Whenever a **trace** passes service boundaries, its context can be transferred via
[context propagation][] and specific headers for e.g. HTTP or [Kafka][].

#### Tracing with OpenTelemetry

I originally started with [OpenTracing][] for this post, but [Quarkus][] finally made the switch
to [OpenTelemetry][] and I had to start from scratch. Poor me, but let us focus on
[OpenTelemetry][] then.

Analogues to [logging][], [Quarkus][] or rather [Smallrye][] comes with an extension to add tracing
capabilities and to enable rudimentary tracing to all HTTP requests by default:

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


###### **application.properties**:
```properties
quarkus.opentelemetry.enabled=true
quarkus.opentelemetry.tracer.exporter.otlp.endpoint=http://localhost:4317
quarkus.opentelemetry.propagators=tracecontext,baggage,jaeger
```

![image](/assets/images/20220115-jaeger_trace.png)

![image](/assets/images/20220115-jaeger_graph.png)

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
https://www.morling.dev/blog/whats-in-a-good-error-message/