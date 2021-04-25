---
layout: post
title: Minikube with hyperkit
date: 2021-03-29 07:29 +0200
author: Christoph Kappel
tags: tools minikube hyperkit virtualbox dns macos
---
I cannot really say what happened, but unfortunately during some of the latest updates
DNS resolution inside of my hyperkit VM stopped working. I can manually set the DNS
to something like *8.8.8.8*, but after a while it fails again.

After some digging around I found this:

[https://github.com/kubernetes/minikube/issues/3036]()

Looks like a local running DNS server for the Bonjour handler clashes with CoreDNS and
results in a non-working DNS configuration inside of kubernetes. That leads to various issues,
but formost problems to fetch any container from docker and the likes.

Surely there are lots of arcane solutions, one of my favorite is to disable the
[System Integrity Protection](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection) and the Bonjour system. Since I don't want
to deal with all the consequences of it yet, there should be another way I can approach.

Solution
----
Alas, the solution is pretty easy: Just don't use hyperkit and switch to virtualbox.
