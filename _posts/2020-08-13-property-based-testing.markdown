---
layout: post
title:  "Property based testing"
date:   2020-08-13 12:10:00 +0200
author: Christoph Kappel
tags:   java testing just-a-link never-tried
---
I initially read about the Python framework
[Hypothesis](https://hypothesis.readthedocs.io/en/latest/) and I must say
I like the overall idea to just define ranges and the framework does dozen of
tests with random values from this range.

This might lead to combinations, you normally wouldn't think of.

~~Now I just need to find time to give it a spin.~~

Update: I found some time to play with a java version of this idea 
([jqwik](https://jqwik.net/)) and so far the outcome looks promising. I found
some easy bugs and the whole handling is pretty straight forward.
