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

On multiple occasions, I thought about setting up a small [Kubernetes][] cluster on my own, but to
be honest the initial drag to get it running usually beats my original usecase *and* every bit of
motivation.

Isn't there something lightweight?

## What is Nomad?

[Nomad][] is a small job scheduler and orchestrator from [HashiCorp][] and relies on plugins
to run nearly anything - given that there is a proper task driver.

There is an exhaustive list of provided task drivers like [Docker][], [Java][] or [fork/exec][]) to
name a few and some of them are community-driven.
Docs [how to provide new ones][] are also available, so expect this list to grow even further.

Before we can start playing with the actual objects, we have to talk about configuration.

### Configuration without YAML

By design, [Kubernetes][] follows a [declarative approach][] and allows to specify the desired
outcome of your objects in a [YAML][] file.
If you want to change something programmatically or even parameterize you can either use the API
directly and patch your objects or rely on tools like [helm][] or [kustomize][].

In contrast to that, [Nomad][] utilizes [Hashicorp][]'s own configuration language [HCL][], which
adds logic to the mix without the syntactic weirdness of [jsonnet][] or [Docker][]'s [CUE][].
It was initially introduced for [Terraform][]

Here is a quick example, but more about it can be found on the [official page][]:

###### **HCL**
```hcl
name = "unexist"
message = "Name: ${name}"
loud_message = upper(message)
options = {
  color: "red",
  amount: 100
}

configuration {
  service "greeter" {
    message = loud_message
    options = var.override_options ? var.override_options : var.options
  }
}
```

Keep that in mind, we might need it later.

### Working with jobs

When you want to run something on [Nomad][] you normally start with a job.
A job - or rather a job file - is the primary work horse and describes in a declarative way the
tasks you want to run.

Behind the scene, whenever a job is submitted, [Nomad][] evaluates it and determines all necessary
steps for this workload.
Once this is done a new **allocation** is created and scheduled on a client node.,

There are many different objects, but it is probably easier just to start with a concrete
example and we are going to step through it line by line:

###### **HCL**
```hcl
job "todo-java" {
  datacenters = ["dc1"] # <1>

  group "web" { # <2>
    count = 1 # <3>

    task "todo-java" { # <4>
      driver = "java" # <5>

      config { # <6>
        jar_path = "/Users/christoph.kappel/Projects/showcase-nomad-quarkus/target/showcase-nomad-quarkus-0.1-runner.jar"
        jvm_options = ["-Xmx2048m", "-Xms256m"]
      }
    }
  }
}
```

**<1>** Sets of multiple client nodes are called a datacenter in [Nomad][]. \
**<2>** Group consist of multiple tasks that must be run together ont he same client node. \
**<3>** Start at most one instance of this group. \
**<4>** This is the actual task definition and the smallest unit inside of [Nomad][]. \
**<5>** The [Java][] task driver allows to run a jar inside of a [JVM][]. \
**<6>** The actual config options for the driver.

### How to start a job

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

## Conclusion

As always, here is my showcase with some more examples:

<https://github.com/unexist/showcase-nomad-quarkus>

```log
https://www.nomadproject.io/docs/internals/plugins/task-drivers
https://github.com/hashicorp/hcl
https://yaml.org/
https://jsonnet.org/
https://docs.dagger.io/1215/what-is-cue/
https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md
https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
```