---
layout: post
title: Mocking vs virtualization
date: %%%DATE%%%
author: Christoph Kappel
tags: tech hoverfly mockito showcase
categories: testing showcase
toc: true
---

## Arquillian

```log
2022-05-03 13:11:22,452 ERROR [co.gi.do.ap.as.ResultCallbackTemplate] (docker-java-stream-1783542465) {} Error during callback: javax.ws.rs.ProcessingException: RESTEASY004655: Unable to invoke request: javax.ws.rs.ProcessingException: RESTEASY003215: could not find writer for content-type application/json type: com.github.dockerjava.core.dockerfile.Dockerfile$ScannedResult$1
```

## Mockito

## Hoverfly

```log
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by com.thoughtworks.xstream.converters.reflection.FieldDictionary (file:/Users/christoph.kappel/.m2/repository/com/thoughtworks/xstream/xstream/1.4.19/xstream-1.4.19.jar) to field java.util.AbstractCollection.MAX_ARRAY_SIZE
WARNING: Please consider reporting this to the maintainers of com.thoughtworks.xstream.converters.reflection.FieldDictionary
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release

com.thoughtworks.xstream.converters.ConversionException: No converter available
---- Debugging information ----
message             : No converter available
type                : java.net.SocketCleanable
converter           : com.thoughtworks.xstream.converters.reflection.ReflectionConverter
message[1]          : Unable to make field jdk.internal.ref.PhantomCleanable jdk.internal.ref.PhantomCleanable.prev accessible: module java.base does not "opens jdk.internal.ref" to unnamed module @e4bb10b
-------------------------------
```

```log
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.codehaus.groovy.vmplugin.v9.Java9 (file:/Users/christoph.kappel/.m2/repository/org/codehaus/groovy/groovy/3.0.8/groovy-3.0.8.jar) to constructor java.lang.AssertionError(java.lang.String)
WARNING: Please consider reporting this to the maintainers of org.codehaus.groovy.vmplugin.v9.Java9
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
```

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
```