---
layout: post
title: Logging vs Tracing
date: 2022-02-18 20:30 +0100
author: Christoph Kappel
tags: tracing jaeger opentelemetry logging kibana elasticsearch fluentd gelf showcase updated
categories: observability showcase
toc: true
---
Monitoring is one of the essential parts to check how well your application is doing and to get
some insights if there is a possible disaster coming in.
Sifting through logs works perfectly well for standalone applications, but what about more complex
scenarios or even [distributed][3] ones?

In this post I want to demonstrate the difference between [logging][19] and [tracing][29] and talk
about why and when I'd prefer one over the other.
We are going to cover some basics first and talk about what both actually is and about possible
ways to enrich them.
And after that, we are going to do a side-by-side comparison and talk about their strengths and
weaknesses for specific usecases.

Are you still with me? Great - let us move on to [logging][19]!

## Logging

### What is a log?

Generally speaking, a **log** is some kind of output of an event that happened on an application
on a specific system at a particular time.
And these logs can be pure informational, like when a user sends a request to your service, but can
also turn the page and deliver helpful bits of information for troubleshooting during an outtake.

One problem with log messages is the sheer amount of data that is generated during daily business,
which makes it quite difficult to keep track of them and to find something specific.
To keep them manageable, they are grouped into different categories (called [levels][17]) like
**Info**, **Warn** or **Error** (depending on their severity) and can be used to filter data
or to create monitoring alarms.

Here is an example of a message:

###### **Logging.java**:
```java
LOGGER.info("Created todo");
```

###### **Log**:
```log
2022-01-19 16:46:14,298 INFO  [dev.une.sho.tod.ada.TodoResource] (executor-thread-0) Created todo
```

### Adding context

Simple messages, like this don't provide much contextual information and make it difficult to
reproduce what has actually happened.
Adding useful information like request-, user- or other object identifiers further improves your
understanding and also makes it possible to correlate different messages.
A good approach here is to consider the log as a journal of your application with details for all
events.

###### **Logging.java**:
```java
LOGGER.info("Created todo: id={}", todo.getId());
```

###### **Log**:
```log
2022-01-19 16:46:14,298 INFO  [dev.une.sho.tod.ada.TodoResource] (executor-thread-0) Created todo: id=8659a492-1b3b-42f6-b25c-3f542ab11562
```

This works for single messages, but what if we have more than one message?

Doing this manually can be a labor intensive and error-prone task and a single deviation makes it
really difficult to find the message:

###### **Logging.java**:
```java
LOGGER.info("Created todo: id ={}", todo.getId());
```

### Mapped Diagnostic Context

Modern [logging][19] libraries support the usage of a [MDC][20], which allows to add information via static
methods to a thread-based context.
If your logger is configured correctly, this information is automatically added to the next log
messages until you remove it again:

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

Unfortunately, the default logger of [Quarkus][25] needs a bit of configuration until it actually
picks up the [MDC][20] information:

###### **application.properties**:
```properties
quarkus.log.console.format=%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c{2.}] (%t) %X %s%e%n
```

After this change the log dutifully includes our value:

###### **Log**:
```log
2022-01-19 16:46:14,298 INFO  [de.un.sh.to.ad.TodoResource] (executor-thread-0) {todo_id=8659a492-1b3b-42f6-b25c-3f542ab11562} Created todo
```

These parameters can either be added manually or automatically via [filters][9],
[interceptors][12] or even with [aspect-oriented-programming][1] and allow writing of better filter
queries for our values.

### Correlation between messages

Another way to correlate between messages is to create an unique id or **correlation id** for each
request and add it to all consecutive log messages.

The combination of both [MDC][20] and [interceptors][12] make it really easy to add this to your
existing applications:

###### **Correlated.java**:
```java
@Target({ METHOD })
@Retention(RUNTIME)
@Documented
@InterceptorBinding
public @interface Correlated { // <1>
}
```

**<1>** Create an annotation for the actual binding of our interceptor

###### **CorrelatedInterceptor.java**:
```java
@Correlated
@Priority(10)
@Interceptor
public class CorrelatedInterceptor {

    @AroundInvoke
    public Object correlate(InvocationContext context) throws Exception {
        Object result = null;

        try (MDC.MDCCloseable closable = MDC.putCloseable("correlation_id",
                UUID.randomUUID().toString())) // <1>
        {
            result = context.proceed(); // <2>
        }

        return result;
    }
}
```

**<1>** Create a new ID here and put it into the MDC \
**<2>** Actual call the intercepted method and pass down our new id

###### **TodoResource.java**:
```java
@POST
@Consumes(MediaType.APPLICATION_JSON)
@Operation(summary = "Create new todo")
@Tag(name = "Todo")
@APIResponses({
        @APIResponse(responseCode = "200", description = "Todo created")
}
@Correlated // <1>
public Response create(TodoBase todoBase) {
    LOGGER.log("Received post request");

    return Response.ok().build();
}
```

**<1>** And this finally marks the method for being intercepted

Once we restart our service and fire a POST request against our service the log should include
something like this:

###### **Log**:
```log
2022-03-05 14:30:06,274 INFO  [de.un.sh.to.ad.TodoResource] (executor-thread-0) {correlation_id=f825c6981cb0dc603eb509189ed141b6} Received post request
```

### Structured logs

To further improve the *searchability* (is that even a word?), switching from an **unstructured**
to a **structured** format allows to parse the data more easily and to better include additional
metadata like the calling class or the host name.
The defacto standard for structured logs is [JSON][14] and supported widely in (business) analytics.

The [quarkus-logging-json][24] extension adds this capability:

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

More advanced [logging][19] libraries provide helpers based on the mechanism of the [MDC][20] to
add key-value pairs conveniently.
Here are few examples:

###### **Logging.java**:
```java
/* quarkus-logging-json */
LOGGER.info("Created todo", kv("todo_id", todo.getId()));

/* Logstash */
LOGGER.info("Created todo", keyValue("todo_id", todo.getId()));

/* Echopraxia */
LOGGER.info("Created todo", fb -> fb.onlyTodo("todo", todo));
```

The first two use helpers to add the specific key-value pair to the log.
[Echopraxia][4] introduces the concept of [field builders][8], which allow to define your own
formatters for your objects to programmatically include all the necessary attributes.

### Central logging

One of the goals of central logging is to have everything aggregated in one place and to provide
some kind of facility to create complex search queries.
There are literally hundreds of other posts about the different solutions and we are going to
focus on [EFK][5] and [gelf][10].

[Quarkus][25] comes with an extension, that does the bulk work for us.
All we have to do is just to include it and configure it for our setup:

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

**<1>** Noteworthy here is [gelf][10] uses UDP by default, so if you want to use [Podman][23] please
keep in mind its [gvproxy][11] doesn't support this yet.

It might take a bit of time due to caching and latency, but once everything has reached [Kibana][16]
you should be able to see something like this:

![image](/assets/images/20220218-kibana_log.png)

Another way to gather information is **tracing**, so let us have a look at it.

## Tracing

### What is a trace?

Again at a high level, a **trace** is a visualization of a request of its way through a service or
a complete microservice environment.
When it is created, it gets an unique **trace ID** assigned and collects **spans** on every step it
passes through.

These **spans** are the smallest unit in the world of distributed tracing and represent any kind
of workflow of your application, like HTTP requests, calls of a database or message handling in
[eventing][6].
They include a **span ID**, specific timings and optionally other attributes, [events][7] or
[statuses][27].

Whenever a **trace** passes service boundaries, its context can be transferred via
[context propagation][2] and specific headers for e.g. HTTP or [Kafka][15].

### Tracing with OpenTelemetry

When I originally started with this post, [Quarkus][25] was about to make the switch from
[OpenTracing][22] to [OpenTelemetry][21] and I had to start from scratch - poor me.

Similar to [logging][19], [Quarkus][25] or rather [Smallrye][26] comes with an extension to bring
[tracing][29] capabilities onto the table.
This also enables rudimentary tracing to all HTTP requests by default:

###### **TodoResource.java**:
```java
@POST
@Consumes(MediaType.APPLICATION_JSON)
@Operation(summary = "Create new todo")
@Tag(name = "Todo")
@APIResponses({
        @APIResponse(responseCode = "200", description = "Todo created")
})
public Response create(TodoBase todoBase) {
    return Response.ok().build();
}
```

Without some kind of visualization it is difficult to explain what **traces** actually look like,
so we fast forward a bit and configure [OpenTelemetry][21] and [Jaeger][13].

Again, [Quarkus][25] comes with some handy extensions and all we have to do is to actually include
them in our `pom.xml` and to update our properties:

###### **pom.xml**:
```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-opentelemetry-exporter-otlp</artifactId>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-extension-trace-propagators</artifactId>
</dependency>
```

###### **application.properties**:
```properties
quarkus.opentelemetry.enabled=true
quarkus.opentelemetry.tracer.exporter.otlp.endpoint=http://localhost:4317
quarkus.opentelemetry.propagators=tracecontext,baggage,jaeger
```

When set up properly your **trace** should look like this in [Jaeger][13]:

![image](/assets/images/20220218-jaeger_simple_trace.png)

There is various meta information included like timing, client_ip or HTTP method and everything is
provided automatically by the [OpenTelemetry][21] integration.
Getting this for free is nice, but a single **span** is nbo big help and we still need to see how
we can enrich this even further.

### Spans in action

The next example adds another service call with its own **span** to the previous example,
demonstrates how they can be connected to each other and how to add more details.

###### **TodoResource.java**:
```java
@Inject
TodoService todoService;

@POST
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
@Operation(summary = "Create new todo")
@Tag(name = "Todo")
@APIResponses({
        @APIResponse(responseCode = "201", description = "Todo created"),
})
public Response create(TodoBase todoBase, @Context UriInfo uriInfo) {
    Response.ResponseBuilder response;

    Span.current()
            .updateName("Received post request"); // <1>

    Optional<Todo> todo = this.todoService.create(todoBase); // <2>

    if (todo.isPresent()) {
        Span.current()
                .setStatus(StatusCode.OK, todo.get().getId()); // <3>

        URI uri = uriInfo.getAbsolutePathBuilder()
                .path(todo.get().getId())
                .build();

        response = Response.created(uri);
    }

    return response.build();
}
```

**<1>** Update the name of the current default span \
**<2>** Create a new todo via service call \
**<3>** Set status code of the current span

###### **TodoService.java**:
```java
@WithSpan("Create todo") // <1>
public Optional<Todo> create(TodoBase base) {
    Todo todo = new Todo(base);

    todo.setId(UUID.randomUUID().toString());

    Span.current()
            .addEvent("Added id to todo", Attributes.of(
                    AttributeKey.stringKey("id"), todo.getId())) // <2>
            .setStatus(StatusCode.OK); // <3>

    return Optional.of(todo);
}
```

**<1>** Create a new span in the current context \
**<2>** Add a logging event with the todo id to the current span \
**<3>** Set status code of the current span

Once sent to [Jaeger][13] something like this can be seen there:

![image](/assets/images/20220218-jaeger_advanced_trace.png)

[Jaeger][13] also includes an experimental graph view to display the call graphs:

![image](/assets/images/20220218-jaeger_advanced_graph.png)

### Even more spans

More complexity?
Let us throw in a bit of [Kafka][15], since I've already mentioned [context propagation][2]:

###### **TodoResource.java**:
```java
@Inject
TodoService todoService;

@Inject
TodoSource todoSource;

@POST
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
@Operation(summary = "Create new todo")
@Tag(name = "Todo")
@APIResponses({
        @APIResponse(responseCode = "201", description = "Todo created"),
})
public Response create(TodoBase todoBase, @Context UriInfo uriInfo) {
    Response.ResponseBuilder response;

    Span.current()
            .updateName("Received post request");

    Optional<Todo> todo = this.todoService.create(todoBase);

    if (todo.isPresent()) {
        Span.current()
                .setStatus(StatusCode.OK, todo.get().getId());

        this.todoSource.send(todo.get()); // <1>

        URI uri = uriInfo.getAbsolutePathBuilder()
                .path(todo.get().getId())
                .build();

        response = Response.created(uri);
    }

    return response.build();
}
```

**<1>** Send the todo object as a message to the broker

###### **TodoSink.java**:
```java
public class TodoSink {
    @ConfigProperty(name = "quarkus.application.name")
    String appName;

    @Inject
    TodoService todoService;

    @Incoming("todo-stored")
    public CompletionStage<Void> consumeStored(IncomingKafkaRecord<String, Todo> record) {
        Optional<TracingMetadata> metadata = TracingMetadata.fromMessage(record); // <1>

        if (metadata.isPresent()) {
            try (Scope ignored = metadata.get().getCurrentContext().makeCurrent()) { // <2>
                Span span = GlobalOpenTelemetry.getTracer(appName)
                        .spanBuilder("Received message from todo-stored").startSpan(); // <3>

                if (this.todoService.update(record.getPayload())) {
                    span.addEvent("Updated todo", Attributes.of(
                            AttributeKey.stringKey("id"), record.getPayload().getId())); // <4>
                }

                span.end();
            }
        }

        return record.ack();
    }
```

**<1>** Load metadata from current message \
**<2>** Activate context from metadata \
**<3>** Create a span builder and start new span \
**<4>** Set status code of the current span

And when finally everything comes together:

![image](/assets/images/20220218-jaeger_complex_trace.png)

(I am going to describe the exact scenario there in a follow-up post.)

I think we have covered enough of the basics and seen both in action, so let us continue with the
actual comparison of [logging][19] and [tracing][29].

### Combining logging and tracing

Currently, there is no easy way in [OpenTelemetry][21] to add a trace or span id to your logs,
but in general both can be used like **correlation id** from the logging example with
[interceptors][12].

When we fetch the **trace id** from the current context, we can append it to the [MDC][20] and et
voila:

###### **TracedInterceptor.java**:
```java
@Traced
@Priority(10)
@Interceptor
public class TracedInterceptor {

    @AroundInvoke
    public Object trace(InvocationContext context) throws Exception {
        Object result = null;

        try (MDC.MDCCloseable closable = MDC.putCloseable("trace_id",
                Span.current().getSpanContext().getTraceId())) // <1>
        {
            result = context.proceed()
        }

        return result;
    }
}
```

**<1>** Fetch the trace id from the context

## Conclusion

[Logging][19] and [tracing][29] aren't mutual exclusive, they both help to pinpoint problems and
provide a different view of the same picture with a complementary set of information.

| Logging                                        | Tracing                                        |
|------------------------------------------------|------------------------------------------------|
| Provides insights into single applications     | Helps to track requests through applications   |
| Captures the state of an application           | Tells request timings and component latencies  |
| Can be easily applied to code                  | Adds more complexity to the code               |
| Is easy to integrate into monoliths            | Makes more sense in microservice architectures |
| Supports debugging and diagnoses               | Supports debugging and diagnoses               |

If you have a microservice architecture it probably makes more sense to enable [tracing][29], than
in your typical monolith, especially when this kind of instrumentation increases the overall
complexity.
[Logging][19] and [tracing][29] are two third of [Three Pillars of Observability][28] and help your
development teams to debug errors, diagnose issues and to build better systems.

If you consider both now, which one would you prefer for what situation?

All of the examples can be found here:

<https://github.com/unexist/showcase-logging-vs-tracing-quarkus>

[1]: https://en.wikipedia.org/wiki/Aspect-oriented_programming
[2]: https://opentelemetry.io/docs/instrumentation/java/manual/#context-propagation
[3]: https://en.wikipedia.org/wiki/Distributed_computing
[4]: https://github.com/tersesystems/echopraxia
[5]: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes
[6]: https://wikidiff.com/messaging/eventing
[7]: https://opentelemetry.io/docs/reference/specification/trace/api/#add-events
[8]: https://github.com/tersesystems/echopraxia#custom-field-builders
[9]: https://blog.adamgamboa.dev/understanding-jax-rs-filters/
[10]: https://www.graylog.org/features/gelf
[11]: https://github.com/containers/gvisor-tap-vsock
[12]: https://www.baeldung.com/cdi-interceptor-vs-spring-aspectj
[13]: https://www.jaegertracing.io/
[14]: https://reflectoring.io/structured-logging/
[15]: https://kafka.apache.org/
[16]: https://www.elastic.co/kibana/
[17]: https://docs.oracle.com/javase/7/docs/api/java/util/logging/Level.html
[18]: https://en.wikipedia.org/wiki/Logging
[19]: https://en.wikipedia.org/wiki/Logging
[20]: https://logback.qos.ch/manual/mdc.hml
[21]: https://opentelemetry.io
[22]: https://opentracing.io/
[23]: https://podman.io/
[24]: https://github.com/quarkiverse/quarkus-logging-json
[25]: https://quarkus.io/
[26]: https://smallrye.io/
[27]: https://opentelemetry.lightstep.com/spans/
[28]: https://www.oreilly.com/library/view/distributed-systems-observability/9781492033431/ch04.html
[29]: https://en.wikipedia.org/wiki/Tracing_(software)