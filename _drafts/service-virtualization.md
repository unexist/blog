---
layout: post
title: Service virtualization
date: %%%DATE%%%
author: Christoph Kappel
tags: tech hoverfly testcontainers podman showcase
categories: testing showcase
toc: true
---
One of the many things developers never tend to agree on is:
What is the right amount of tests?

A quick look at the [testing pyramid][] should give us the answer, **if** we are both looking at
the same same pyramid, with the same [orientation][] and actually the same shape.
Does the the [testing diamond][] ring a bell?

Still, what we can gather from all of the **testing shapes** is that integration testing is
something with probably higher costs in time than unit tests.

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