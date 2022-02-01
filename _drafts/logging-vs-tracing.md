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

## Tell a Domainstory

In this post I want to demonstrate the difference of [logging][] and [tracing][], so we are going
to use a totally contrived example with needless complexity, just to prove my point. I hadn't had
time to start with a post about [Domain Storytelling][], but I think this format is well-suited to
give an overview about what is supposed to happen:

![image](/assets/images/20220115-overview.png)

That is probably lots of information to the untrained eye, so let me break this down a bit.

### Get the whole story

One of the main drivers of [Domain Storytelling][] is to convey information step-by-step in
complete sentences. Each step is one action item inside of the story and normally just covers one
specific path - the happy path here.

This is still probably difficult to grasp, so fire up your browser, it is time for some first
hand experience:

1. Download the [source file][] from the repository.
2. Point your browser to <https://egon.io>.
3. Import the downloaded file with the **up arrow icon** on the upper right.
4. Click on the **play icon** and start the replay.

### How to read it?

Once you start with the first step of the story, you should see something like this:

![image](/assets/images/20220115-step1.png)

This is the actual first step of the story and can be read like:

> A User sends a Todo to the todo-service-create

Can you follow the story and understand the next step? Give it a try with either the **next icon**
the **prev icon** from the toolbar.

### Disclaimer

*Before experts blame me: I admit this **digitalized** (includes technology; the preferred way is to
omit it altogether) [Domainstory][] is really broad, but I will conclude on this later - promised.*

Let us move on to logging.

### Logging

#### What is a log?

A log is a timestamped event that happened at a particular time on a system. These logs can be pure
informational like when a user sends a request to your service, but can also carry helpful bits of
information to figure out what exactly went wrong in troubleshooting. There are different
categories (or levels) for log messages like  **Info**, **Warn** or **Error**, which can be used to
filter the data and/or create monitoring alarms.

Figuring out what is good information and what is just line noise can be quite difficult, so
logging can get quite messy, difficult to stay manageable and consumes lots of disk space when
aggregated at a central place.

#### Structured logs

Normally, logs are unstructured and it can become a challenge to query them for something
specific. An easy solution here is to create log entries in a structured format, which
can be parsed easily. The standard format is JSON and many logging libraries come with integrated
support.

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

Included is lots of meta information by default like the calling class, the method or the host
and each piece of information can be used to fine-tune your search results in e.g. [Kibana][]:

![image](/assets/images/20220115-kibana_search.png)

##### Add meta information

If you have a closer look at our example, the message `Created todo` is no help at all without any
kind of context like the working object it created or its attributes at least. One way is to just
append it to the log message itself, but this kind of beats the idea to have something structured,
which is also easy to search through.

Most of the logging libraries support the usage of [Mapped Diagnostic Context][] (or **MDC**) to
provide exactly that. The essential points here are it consists of some static methods and keeps
the information per-thread until you remove it again:

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

More advanced logging libraries also provide key-value-helpers to conveniently add information
to the output:

###### **Logging.java**:
```java
/* quarkus-logging-json () */
LOGGER.info("Created todo", kv("todo", todo), kv("foo", "bar"));

/* Logstash */
LOGGER.info("Created todo", keyValue("todo", todo), keyValue("foo", "bar"));

/* Echopraxia */
LOGGER.info("Created todo", fb -> List.of(fb.todo("todo", todo), fb.string("foo", "bar")));
```

The first two are probably easy to understand, the latter one comes with a nice concept of
field builders as formatter for your objects. If this sounds and look interesting head over to
[Echopraxia][] and give it a spin.

If you manage to add data into the [MDC][] and your [logshipper][] actually includes it,
something like this could be visible in [Kibana][]:

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

I didn't provide any fancy output format of the `Todo` object, but you still should get the point.

### Tracing

Tracing or rather distributed tracing needs a bit of explanation, because it comes with some
concepts, which are required to really understand what is going on.

In general, a **trace** is a collection of [spans][], which function as the smallest unit in the
world of tracing. They represent any kind of workflow of your application like HTTP requests, calls
of a database or even message handling in [eventing][].

Each trace gets a unique **trace ID** on creation and keeps it, while it is passed via
[context propagation][] from one point to another in your landscape. On each step, a new [span][]
with a **span ID** is created and can additionally carry other useful information like [tags][], a
status or other [attributes][].

![image](/assets/images/20220115-jaeger_trace.png)

In the example above you can see a trace, that consists of 20 spans, passed three services and
took 3.73s in total.

#### Tracing with OpenTelemetry

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