---
layout: post
title:  "Value objects"
date:   2020-09-16 12:00:00 +0200
author: Christoph Kappel
tags:   tools ddd frameworks
---
Here, whenever we are talking about the general topic **value objects**, sooner
or later we end up in a discussion about functionality.

*What kind of functionality should be in a value object and what not?*

One of the easiest examples is probably unit types. What you really want
is to have some basic type for units like distances, weights and so on. And when
using them, the most beneficial handling would be, if they encapsulate all logic
related to basic arithmetic:

```java
Kilometer distanceInKilometer = 1;
Meter distanceInMeter = 5;

Kilometer totalDistance = distanceInMeter + distanceInKilometer;
```

So why do even mention this contrived example? I stumbled upon 
[Manifold framework](https://manifold.systems/) and along other useful things
like `@Jailbreak` to access private methods and `#define/#ifdef`, it comes
with a really cool way to handle unit types.

I know strictly speaking this has isn't even closely related to **DDD**, but it
still cool and hey, clickbait.
