---
layout: post
title: Logging vs Tracing
date: %%%DATE%%%
author: Christoph Kappel
tags: tracing jaeger opentelemetry logging kibana elascticsearch fluentd gelf showcase
categories: observability showcase
toc: true
---
If you talk to developers about what they need to see what is happening in an application, they
usually tell you about logs and sometimes even about [structured][] ones, which include a bit
more meta  information, than the stuff the original developer deemed necessary at the time of
writing.

This can work pretty well for standalone applications, but what about [distributed][] ones? Todays
systems easily span across dozen of services on different nodes and have a quite complex call
hierarchy.

Let us start this post with two images, pick the one you would prefer, on let us say a Friday
evening, when something is wrong and you are losing data on production:

| Logging                                      | Tracing                                      |
|----------------------------------------------|----------------------------------------------|
| ![image](/assets/images/20220115-kibana.png) | ![image](/assets/images/20220115-jaeger.png) |

## Conclusion

All of the examples can be found here:

<https://github.com/unexist/showcase-logging-vs-tracing-quarkus>