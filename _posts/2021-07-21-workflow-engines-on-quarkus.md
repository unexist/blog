---
layout: post
title: Workflow engines on Quarkus
date: 2021-07-21 17:15 +0200
author: Christoph Kappel
tags: tools workflow-engine rules-engine camunda kogito quarkus kafka redpanda messaging showcase
categories: tech showcase
toc: true
---
Discussions about flexibility as a requirement, usually lead to workflow engines and although
they are more a technical solution, than a real requirement, it is time to to re-evaluate the
current state of the support for [Quarkus][1].

When you fire up Google and ask it for `workflow engine quarkus`, there is usually [Camunda][2] and
[Kogito][3] in the top10 of the results, so let us test both of them.

## Camunda

One of the better known engines, [Camunda][2] provides a rich feature set, a pretty mature codebase
(0.7.15, >7 years) and surely cannot be a bad start.

### Installation

Although I've never seen [Camunda][2] outside of a [SpringBoot][4] context, their page states that
there is an [embeddable engine][5], which can be used inside of JAX-RS implementations. So this
*should* and actually does partly work within [Quarkus][1].

The essential dependencies are following with versions from the current BOM of [Camunda][2]:

###### **pom.xml**:
```xml
<dependency>
    <groupId>org.camunda.bpm</groupId>
    <artifactId>camunda-engine</artifactId>
</dependency>
<dependency>
    <groupId>org.camunda.bpm</groupId>
    <artifactId>camunda-engine-rest</artifactId>
    <classifier>classes</classifier>
</dependency>
```

### Modelling

There aren't many examples available, so it took me quite a while to get the engine running. After
that and when I refreshed my knowledge how to actually create a BPMN diagram, I got a small and
totally exciting example working:

![image](/assets/images/workflow_engines_on_quarkus/camunda_modeler.png)

_On the pro sides, the [Camunda Modeler][6] is quite usable now (but still looks like a Java
applet). I had different memories and ultimately generated the diagram by code, to avoid some of
the problems with it, back then._

### Problems

There are a few noteworthy gotchas here:

###### How to use a datasource?

[Quarkus][1] does not support JNDI, so the datasource *must* be passed to engine manually and the
engine only way to access it is via CDI. An easy way here just to include [agroal][7] and inject the
default datasource:

###### **pom.xml**:
```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-jdbc-h2</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-agroal</artifactId>
</dependency>
```

###### **CamundaEngine.java**:
```java
@Inject
AgroalDataSource defaultDataSource;
```

*NOTE: Setting the JDBC URL always prevented H2 from starting for me, so you also might want*
to check or rather avoid that.

###### How to use CDI?

[Camunda][2] also supports model integration for CDI, so the only thing that has to be done is
adding  [engine-cdi][8] as a dependency. Unfortunately, it relies on CDI features which are not
supported (will probably be supported) by the CDI ([ArC][9]) implementation of [Quarkus][1].

If you are interested in more backstory and a way to bypass this, please have a look here:

<https://javahippie.net/java/microprofile/quarkus/camunda/cdi/2020/02/07/camundaquarkus.html>

According to the [Camunda][2] developers they are aware of this problem and plan on releasing an
extension for [Quarkus][1] to fix this problem within their next release in October:

<https://jira.camunda.com/browse/CAM-13628>

###### JSON handling is quite troublesome.. Why?

According to all the stuff I've read about, you just want to use the [spin extension][10] wherever
possible. This doesn't solve all problems, especially if you want to handle time and date, but
every Java developer should be well aware of it.

###### What is the REST path to the engine?

And just a minor issue, which actually took me quite a whole to understand: The path to the engine
has been changed recently in [Camunda][2]:

###### **Shell**:
```log
Old: http://localhost:8080/rest/engine/default/process-definition/key/todo/start
New: http://localhost:8080/engine-rest/engine/default/process-definition/key/todo/start
```

## Kogito

Time to move on and check [Kogito][3]:

> Kogito is designed from ground up to run at scale on cloud infrastructure. If you think about
business automation think about the cloud as this is where your business logic lives these days.
By taking advantage of the latest technologies (Quarkus, knative, etc.), you get amazingly fast
boot times and instant scaling on orchestration platforms like Kubernetes.
<cite>[https://kogito.kie.org/][3]</cite>

Looking at this quote, they apparently are *not* afraid of bold statements. Although this project
is in comparison to [Camunda][2] quite young (1.8.0, >2 years), it surely comes with a impressive
feature set.

[Kogito][3] provides an extension for [Quarkus][1], so the installation is pretty straight forward:
All it really takes is to add one dependency:

###### **pom.xml**:
```xml
<dependency>
    <groupId>org.kie.kogito</groupId>
    <artifactId>kogito-quarkus</artifactId>
</dependency>
```

Starting with [Quarkus][1] `2.1.0.CR1` it looks like the extension is part of the official group
and according to [this example][12] this should work, if you use a current snapshot. It never did for
me, but I will still mention it here for completeness:

###### **pom.xml**:
```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-kogito</artifactId>
</dependency>
```

### Modelling

With the help of their web-based and *colorful* [online modeler][13], it was quite easy to get an
initial workflow. Apparently, playing with it is quite funny and even CDI works out-of-the-box, so
after a while I ended with up this:

![image](/assets/images/workflow_engines_on_quarkus/kogito_modeler.png)

### Rules engine

One of the things I really liked is the easy integration of the rules engine [Drools][14], which
allows to write business rules in a DSL-like language:

###### **todo.drl**:
```drl
package dev.unexist.showcase.todo.adapter;
dialect  "mvel"

import dev.unexist.showcase.todo.domain.todo.TodoBase;

rule "isDone" ruleflow-group "TodoUpdater"
    when
        $todo: TodoBase(done != true)
    then
        modify($todo) {
            setDone(true)
```

Other really interesting features are to directly interface with [Kafka][15] and an available
[operator][16] for [Kubernetes][17]. I really have to look into this operator, but let us talk about
accessing messaging via [Kafka][15]:

### Messaging

I did know that there are [devservices][18] available since `v1.13` and I also did a few tests with
a database in another showcase, but to my surprise the current version also uses a [devservice][18]
for [Kafka][15]. Surprisingly, it not [Kafka][15] directly, but a reimplementation and API
compatible project with the lovely name [Redpanda][19].

It comes with its own complete set of tools, which can be used to e.g. access topics:

###### **pom.xml**:
```shell
$ brew install vectorizedio/tap/redpanda
$ rpk topic --brokers localhost:55019 list
$ rpk topic --brokers localhost:55019 create topic_in --replicas 1
```

After a bit of testing, I must admit [Redpanda][19] is blazingly fast, I am really impressed.

Another thing that has to be included manually is the addon for [CloudEvents][20], somehow it is
not pulled automatically:

###### **pom.xml**:
```xml
<dependency>
    <groupId>org.kie.kogito</groupId>
    <artifactId>kogito-addons-quarkus-cloudevents</artifactId>
</dependency>
```

###### More modelling

That out of the way, we can finally start modelling a new workflow with a message consumer and
producer:

![image](/assets/images/workflow_engines_on_quarkus/kogito_modeler_messaging.png)

### Problems

###### Fire rule limit - what?

If you ever see this inside of your log, it just means there is a rule that is called repetitively
until a stack limit is reached. In my case it was just a test rule with a condition which could
never be fulfilled.

###### **Log**:
```log
Fire rule limit reached 10000, limit can be set via system property org.jbpm.rule.task.firelimit or
via data input of business task named FireRuleLimit
```

###### How to configure the topics?

Since we are using a [devservice][18] the configuration part like the broker URL is done for us
automatically. Still, I kind of missed a really essential part of the documentation:

###### **application.properties**:
```properties
# Messaging
mp.messaging.incoming.kogito_incoming_stream.connector=smallrye-kafka
mp.messaging.incoming.kogito_incoming_stream.topic=todo_in
mp.messaging.incoming.kogito_incoming_stream.value.deserializer=org.apache.kafka.common.serialization.StringDeserializer

mp.messaging.outgoing.kogito_outgoing_stream.connector=smallrye-kafka
mp.messaging.outgoing.kogito_outgoing_stream.topic=todo_out
mp.messaging.outgoing.kogito_outgoing_stream.serializer=org.apache.kafka.common.serialization.StringSerializer
```

Due to the internal wiring of [Kogito][3], the incoming (`kogito_incoming_stream`) and the outgoing
(`kogito_outgoing_stream`) channels have *specific and fixed* names and any other name just
*doesn't* work.

Another thing, that is easy to miss: The message name inside of the properties of the
`start message` or `end message` *must to be* the name of topic the message should be read from or
respectively send to:

![image](/assets/images/workflow_engines_on_quarkus/kogito_modeler_messaging_config.png)

## Benchmark

I also did some benchmarks with [wrk][21], to get some numbers on it, which probably speak for
themselves:

###### **payload.lua**:
```lua
wrk.method = "POST"
wrk.body   = '{ "todo": { "description": "string", "done": false, "dueDate": { "due": "2022-05-08", "start": "2022-05-07" }, "title": "string" }}'
wrk.headers["Content-Type"] = "application/json"
```

###### **Camunda**:
```shell
$ wrk -t1 -c1 -d30s -s payload.lua http://127.0.0.1:8080/camunda​
Running 30s test @ http://127.0.0.1:8080/camunda​
  1 threads and 1 connections​
  Thread Stats   Avg      Stdev     Max   +/- Stdev​
    Latency     1.88ms    1.28ms  26.86ms   96.25%​
    Req/Sec   570.89     93.65   710.00     69.00%​
  17077 requests in 30.06s, 1.47MB read​
Requests/sec:    568.17​
Transfer/sec:     50.15KB
```

###### **Kogito**:
```shell
$ wrk -t1 -c1 -d30s -s payload.lua http://127.0.0.1:8080/kogito
Running 30s test @ http://127.0.0.1:8080/kogito
  1 threads and 1 connections​
  Thread Stats   Avg      Stdev     Max   +/- Stdev​
    Latency    60.27ms  269.05ms   1.97s    95.13%​
    Req/Sec     1.07k   278.63     1.49k    70.82%​
  30079 requests in 30.07s, 6.40MB read​
Requests/sec:   1000.16​
Transfer/sec:    217.81KB
```

## Conclusion

I have to look into [Camunda][2] again, once the new version has been released. Currently I'd
suggest to pick [Kogito][3] and give it a try. The impressive feature set, the ease of use and also
the fact, that it already is a good cloud-native citizen is something to consider.

My showcase can be found here:

<https://github.com/unexist/showcase-workflow-quarkus>

[1]: https://quarkus.io
[2]: https://camunda.com
[3]: https://kogito.kie.org/
[4]: https://spring.io/projects/spring-boot
[5]: https://docs.camunda.org/manual/7.15/reference/rest/overview/embeddability/
[6]: https://camunda.com/products/camunda-platform/modeler/
[7]: https://quarkus.io/guides/datasource
[8]: https://docs.camunda.org/manual/7.15/user-guide/cdi-java-ee-integration/
[9]: https://quarkus.io/blog/quarkus-dependency-injection/
[10]: https://github.com/camunda/camunda-spin
[11]: https://quarkus.io/blog/quarkus-dependency-injection/
[12]: https://github.com/mswiderski/kogito-quickstarts/blob/master/kogito-kafka-quickstart-quarkus/pom.xml
[13]: https://kiegroup.github.io/kogito-online/#/editor/bpmn
[14]: https://www.drools.org/
[15]: https://kafka.apache.org/
[16]: https://github.com/kiegroup/kogito-operator
[17]: https://kubernetes.io/
[18]: https://quarkus.io/guides/dev-services
[19]: https://github.com/vectorizedio/redpanda
[20]: https://cloudevents.io
[21]: https://github.com/wg/wrk