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

Another problem is logs are normally unstructured, which makes it a challenge to query them for
something specific. An easy solution to this is to create log entries in a structured format, which
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

##### Add meta information

###### **Structured log**:
```json
{
    "@timestamp": "2022-01-20T09:02:49.917000055+00:00",
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
    "SourceMethodName": "create"
}
```


###### **Logging.java**:
```java
/* quarkus-logging-json (https://github.com/quarkiverse/quarkus-logging-json) */
LOGGER.info("Created todo", kv("todo", todo), kv("foo", "bar"));

/* Logstash */
LOGGER.info("Created todo", keyValue("todo", todo), keyValue("foo", "bar"));

/* Echopraxia */
LOGGER.info("Created todo", fb -> List.of(fb.todo("todo", todo), fb.string("foo", "bar")));

/* Base MDC */
MDC.put("todo", todo.get().toString());
MDC.put("foo", "bar");
LOGGER.info("Created todo");
MDC.remove("todo");
MDC.remove("foo");
```

###### **TodoService.java**:
```java
private static final Logger LOGGER = LoggerFactory.getLogger(TodoResource.class); /// <1>

private static final Logger<Todo.FieldBuilder> LOGGER = LoggerFactory.getLogger(TodoService.class)
    .withFieldBuilder(Todo.FieldBuilder.class); // <1>

public Optional<Todo> create(TodoBase base) {
    Todo todo = new Todo(base);

    todo.setId(UUID.randomUUID().toString());

    await().between(Duration.ofSeconds(1), Duration.ofSeconds(10));

    LOGGER.info("Created todo: {}",
            fb -> List.of(fb.todo("todo", todo))); // <2>

    return Optional.of(todo);
}
```

**<1>** Create logger \
**<2>** Use the field builder to create the log entry

### Tracing

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
https://www.innoq.com/en/blog/structured-logging/
https://github.com/quarkusio/quarkus/issues/18228
https://quarkus.io/guides/centralized-log-management