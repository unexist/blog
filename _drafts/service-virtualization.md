---
layout: post
title: Service virtualization
date: %%%DATE%%%
author: Christoph Kappel
tags: tech hoverfly testcontainers podman showcase
categories: testing showcase
toc: true
---
If you've ever written a test for software, that wasn't designed to be tested, you probably know the
problem of mixed up business logic through-out the layers.
And it gets even worse, when your use case isn't isolated into a single service and relies on some
external communication with other ones.

Containerization e.g. via [Podman][] eases the pain and allows to run instances of all required
services along with our service in a complex integration test.
Alas, this solution doesn't scale well, especially when the required services have further
requirements themselves and you basically have to start up a whole landscape or are really difficult
to set up.

In this post I want to demonstrate another option namely **service virtualization**, which allows
to consider these kind of requirements as a blackbox and (to further stretch this metaphor) to
record and playback requests.

Sounds interesting? Let me introduce you to [Hoverfly][].

## Hoverfly

Simply speaking, [Hoverfly][] acts like a transparent proxy and can be easily hooked up into the
[JVM][] via the [JUnit5][] extension lifecycle.
From there, it can record requests, simulate them or even do both at once, when the destination
address isn't reachable.
And it is also possible to define replies to requests with a [DSL][].




## Problems

- TestRessource is always started
```java
@QuarkusTestResource(value = HoverflyResource.class, restrictToAnnotatedClass = true)
```

## Conclusion

<https://github.com/unexist/showcase-integration-testing-quarkus>

```
https://hoverfly.io/
https://docs.hoverfly.io/projects/hoverfly-java/en/latest/pages/junit5/junit5.htm
```