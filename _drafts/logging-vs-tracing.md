---
layout: post
title: Logging vs Tracing
date: %%%DATE%%%
author: Christoph Kappel
tags: tracing jaeger opentelemetry logging kibana elascticsearch fluentd gelf showcase
categories: observability showcase
toc: true
---
If you talk to developers about what they need to figure out  what is happening in an application,
they usually tell you about logs or logging stacks. More experienced ones might also throw in
[structured logs][], which include some more meta information, than the stuff the original
developer deemed necessary at the time of writing.

This can work pretty well for standalone applications, but what about [distributed][] ones? Todays
systems easily span across dozen of services on different nodes and have a quite complex call
hierarchy.

## Tell me a Domainstory

I want to demonstrate the difference of [logging][] and [tracing][], so we are going to use a
totally contrived example with needless complexity, just to prove my point. I hadn't had time to
start with a post about [Domain Storytelling][], but I think it is well-suited to give an overview
about what is happening:

![image](/assets/images/20220115-overview.png)

This is probably still difficult to understand, especially when you've never seen such a diagram
before. One of the main drivers of [Domain Storytelling][] is to be able to tell a story and the
modeler is able to replay it based on the numbers:

1. Download the [source file][] from the repository.
2. Browse to the [modeler][].
3. Import the file with the **up arrow icon** on the upper right.
4. Click on the **play icon** and start the replay.
5. And browse through the steps via **next icon** or **prev icon**

Just for a starter, read the first steps like this:

> 1. A User sends a Todo to the todo-service-create
> 2. The todo-service-create assigns an id to a Todo
> 3. ...

This [Domainstory][] is **digitalized** and way too big, but I will conclude on that in an
upcoming post - promised.

## Logging vs Tracing

Now that we have a common understanding what this example is all about, let us get started with
our comparison of [logging][] and [tracing][]. I think the first big difference is the visuals:

| Logging ([Kibana][])                        | Tracing ([Jaeger][])                         |
|----------------------------------------------|----------------------------------------------|
| ![image](/assets/images/20220115-kibana.png) | ![image](/assets/images/20220115-jaeger.png) |

### Logging

On the left side we see a typical [EFK][] stack with an excerpt of the entries of our use case. I
said excerpt, because there are several lines missing - there are 19 in total. Each of them
describes only a single instance and includes no further context.

###### **Log**:
```java
LOGGER.info("Updated todo: {}",
    fb -> List.of(fb.todo("todo", todo)));
```

### Tracing

## Conclusion

[Logging][] and [Tracing][] aren't mutual exclusive..

All of the examples can be found here:

<https://github.com/unexist/showcase-logging-vs-tracing-quarkus>


https://github.com/unexist/showcase-logging-tracing-quarkus/blob/master/docs/todo.dst
https://egon.io
https://github.com/tersesystems/echopraxia