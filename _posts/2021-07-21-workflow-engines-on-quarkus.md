---
layout: post
title: Workflow engines on Quarkus
date: 2021-07-21 17:15 +0200
author: Christoph Kappel
tags: tools workflow-engine camunda kogito quarkus showcase
categories: tech
---
Discussions about flexibility as a requirement, usually lead to workflow engines and although
they are more a technical solution, than a real requirement, it is time to to re-evaluate the
current state of the support for [Quarkus][1].

When you fire up Google and ask it for `workflow engine quarkus`, there is usually [Camunda][2] and
[Kogito][3] in the top10 of the results, so let us test both of them.

## Camunda

One of the better known engines, [Camunda][2] provides a rich feature set, a pretty mature codebase
(0.7.15, >7 years) and surely cannot be a bad start.

Although I've never seen [Camunda][2] outside of a [SpringBoot][4] context, their page states that
there is an embedable engine, which can be used inside of JAX-RS implementations. So this *should*
work within [Quarkus][1].

There aren't many examples available, so it took me quite a while to get the engine running. After
that and when I refreshed my knowledge how to actually create a BPMN diagram, I got a small and
totally exciting example working:

![image](/assets/images/20210721-camunda_modeler.png)

_On the pro sides, the [Camunda Modeler][6] is quite usable now (but still looks like a Java
applet). I had different memories and ultimately generated the diagram by code, to avoid some of
the problems with it, back then._

### Problems

There are a few noteworthy gotchas here:

#### How to use a datasource?

[Quarkus][1] does not support JNDI, so the datasource *must* be passed to engine manually. Oh and
the only way to access it is via CDI.

#### How to use CDI?

[Camunda][2] also supports model integration for CDI, so the only thing that has to be done is
adding  [engine-cdi][7] as a dependency. Unfortunately, it relies on CDI features which are not
supported (will probably be supported) by the CDI ([ArC][8]) implementation of [Quarkus][1].

If you are interested in more backstory and a way to bypass this, please have a look here:

<https://javahippie.net/java/microprofile/quarkus/camunda/cdi/2020/02/07/camundaquarkus.html>

According to the [Camunda][2] developers they are aware of this problem and plan on releasing an
extension for [Quarkus][1] to fix this problem within their next release in October:

<https://jira.camunda.com/browse/CAM-13628>

#### What is the REST path to the engine?

And just a minor issue, which actually took me quite a whole to understand: The path to the engine
has been changed recently in [Camunda][2]:

#### **Shell**:
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

#### **pom.xml**:
```xml
<dependency>
    <groupId>org.kie.kogito</groupId>
    <artifactId>kogito-quarkus</artifactId>
</dependency>
```

With the help of their web-based and *colorful* [online modeler][9], it was quite easy to get an
initial workflow. Apparently, playing with it is quite funny and even CDI works out-of-the-box, so
after a while I ended with up this:

![image](/assets/images/20210721-kogito_modeler.png)

One of the things I really liked is the easy integration of the rules engine [Drools][10],
which allows to write business rules in a DSL-like language:

#### **todo.drl**:
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

Another really interesting feature is to directly interface with [Kafka][11] or the available
[operator][12] for [Kubernetes][13]. I really have to look into this some day.

## Benchmark

I also did some benchmarks with [wrk][14], to get some numbers on it, which probably speak for
themselves:

#### **payload.lua**:
```lua
wrk.method = "POST"
wrk.body   = '{ "todo": { "description": "string", "done": false, "dueDate": { "due": "2022-05-08", "start": "2022-05-07" }, "title": "string" }}'
wrk.headers["Content-Type"] = "application/json"
```

#### **Camunda**:
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

#### **Kogito**:
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
[7]: https://docs.camunda.org/manual/7.15/user-guide/cdi-java-ee-integration/
[8]: https://quarkus.io/blog/quarkus-dependency-injection/
[9]: https://kiegroup.github.io/kogito-online/#/editor/bpmn
[10]: https://www.drools.org/
[11]: https://kafka.apache.org/
[12]: https://github.com/kiegroup/kogito-operator
[13]: https://kubernetes.io/
[14]: https://github.com/wg/wrk
