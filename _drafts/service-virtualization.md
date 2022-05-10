---
layout: post
title: Service virtualization
date: %%%DATE%%%
author: Christoph Kappel
tags: tech hoverfly testcontainers podman showcase
categories: testing showcase
toc: true
---
If you've even written a test for software, that wasn't designed to be tested, you probably know the
problem of mixed up business logic through-out the layers.
This is especially hard, when your business case isn't isolated to a single services and relies
on some kind of communication with other ones.

Nowadays, our the best shot is containerization e.g. via [Podman][] and just run an instance of
the required service along with our service in a messed up integration test.

In this post I want to demonstrate another option called *service virtualization*, when you really
just need the reply of a service and can keep it as a black box.

## Hoverfly

## Problems

- TestRessource is always started
```java
@QuarkusTestResource(value = HoverflyResource.class, restrictToAnnotatedClass = true)
```

## Conclusion

<https://github.com/unexist/showcase-integration-testing-quarkus>

```
https://github.com/quarkusio/quarkus/issues/9884
https://issues.apache.org/jira/browse/GROOVY-8339

https://github.com/quarkusio/quarkus/pull/14821
https://github.com/quarkusio/quarkus/issues/14823

https://docs.hoverfly.io/projects/hoverfly-java/en/latest/pages/junit5/junit5.htm

https://www.testcontainers.org/features/configuration/
https://quarkus.io/guides/maven-tooling#uber-jar-maven

https://martinfowler.com/articles/practical-test-pyramid.html
https://sqa.stackexchange.com/questions/37623/is-an-inverted-test-pyramid-really-an-anti-pattern
https://engineering.atspotify.com/2018/01/testing-of-microservices/
```