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
they usually tell you about logs or logging stacks. More experienced ones might also throw in
[structured logs][], which include more meta information, than the stuff the original developer
deemed necessary at the time of writing.

This can work pretty well for standalone applications, but what about [distributed][] ones? Todays
systems easily span across dozen of services on different nodes and have a quite complex call
hierarchy.

## Tell a Domainstory

I want to demonstrate the difference of [logging][] and [tracing][], so we are going to use a
totally contrived example with needless complexity, just to prove my point. I hadn't had time to
start with a post about [Domain Storytelling][], but I think it is well-suited to give an overview
about what is happening:

![image](/assets/images/20220115-overview.png)

This is probably still difficult to understand, especially when you've never seen such a diagram
before. One of the main drivers of [Domain Storytelling][] is to convey information as a story
and the modeler is able to replay it based on the numbers:

1. Download the [source file][] from the repository.
2. Point your browser to <https://egon.io>.
3. Import the downloaded file with the **up arrow icon** on the upper right.
4. Click on the **play icon** and start the replay.
5. And step through the story with either the **next icon** or the **prev icon**.

Just for a starter, read the first steps like this:

> 1. A User sends a Todo to the todo-service-create
> 2. The todo-service-create assigns an id to a Todo
> 3. ...

Before experts blame me: I admit this [Domainstory][] is **digitalized** (includes technology) and
way too big, but I will conclude on that in an upcoming post - promised.

Now that we have a common understanding what this example is all about, let us get started with
a quick introduction of [logging][] and [tracing][].

### Logging

#### What is logging?

On a high level, logging is the aggregation of log entries and those are can be defined as
timestamped events, that happened inside a system or rather an application at a specific time.

#### Structured logs

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