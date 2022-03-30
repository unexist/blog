---
layout: post
title: Mocking vs virtualization
date: %%%DATE%%%
author: Christoph Kappel
tags: tech hoverfly mockito showcase
categories: testing showcase
toc: true
---

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

## Conclusion

<https://github.com/unexist/showcase-arquillian-quarkus>