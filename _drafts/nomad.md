---
layout: post
title: Nomad
date: %%%DATE%%%
last_updated: %%%DATE%%%
author: Christoph Kappel
tags: nomad kubernetes orchestration showcase
categories: showcase
toc: true
---
When I think about orchestration, [Kubernetes][] is something that easily comes up to my mind.
With its massive ecosystem and all the different companies, that provide even more services, it is
a big solution to ~~even bigger~~ *enterprisy* problems.

On multiple occasions I thought about setting up a small [Kubernetes][] cluster on my own, but to
be honest the initial drag to get it running usually beat my original usecase *and* every bit of
motivation.

Isn't there something more lightweight?

## What is Nomad?

[Nomad][] is a small and task scheduler and orchestrator from [HashiCorp][] and relies on plugins
to run nearly anything - given that there is a proper task driver.

There is an exhaustive list of provided task drivers like [Docker][], [Java][] or [fork/exec][]) to
name a few and some of them are community-driven.
Docs [how to provide new ones][] are also available, so expect this list to grow even further.

### Configuration without YAML

By design, [Kubernetes][] follows a declarative approach and allows to specify the desired outcome
of your objects in a [yaml][] file.
To add a bit of logic you either need to rely on tools like [helm][] or [kustomize][] or script it
on your own.
In contrast to that, [Nomad][] utilizes [Hashicorp][]'s own configuration language [HCL][].
It was initially introduced for [Terraform][] and adds declarative logic to mix, without the
syntactic weirdness of [jsonnet][] or [CUE][].

```hcl
```

### Task drivers

One of the simplest ones is the java task driver:


```hcl
job "todo-java" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    task "service" {
      driver = "java"

      config {
        jar_path = "/Users/christoph.kappel/Projects/showcase-nomad-quarkus/target/showcase-nomad-quarkus-0.1-runner.jar"
        jvm_options = ["-Xmx2048m", "-Xms256m"]
      }
    }
  }
}
```

```shell
$ nomad job run jobs/todo-java.nomad
==> 2022-07-06T16:56:43+02:00: Monitoring evaluation "15d0134b"
    2022-07-06T16:56:43+02:00: Evaluation triggered by job "todo-java"
==> 2022-07-06T16:56:44+02:00: Monitoring evaluation "15d0134b"
    2022-07-06T16:56:44+02:00: Evaluation within deployment: "0f144847"
    2022-07-06T16:56:44+02:00: Allocation "85fd5897" created: node "25817ed6", group "web"
    2022-07-06T16:56:44+02:00: Evaluation status changed: "pending" -> "complete"
==> 2022-07-06T16:56:44+02:00: Evaluation "15d0134b" finished with status "complete"
==> 2022-07-06T16:56:44+02:00: Monitoring deployment "0f144847"
  ✓ Deployment "0f144847" successful

    2022-07-06T16:56:55+02:00
    ID          = 0f144847
    Job ID      = todo-java
    Job Version = 0
    Status      = successful
    Description = Deployment completed successfully

    Deployed
    Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
    web         1        1       1        0          2022-07-06T17:06:53+02:00
```

```shell
$ nomad job status
ID         Type     Priority  Status   Submit Date
todo-java  service  50        running  2022-07-06T16:56:43+02:00
```

```log
https://www.nomadproject.io/docs/internals/plugins/task-drivers
https://github.com/hashicorp/hcl
https://docs.dagger.io/1215/what-is-cue/
```