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

## Configuration without YAML

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
colors = [ "red", "blue" ]
options = {
  color: element(colors, 1),
  amount: 100
}

configuration {
  service "greeter" {
    message = loud_message
    options = var.override_options ? var.override_options : var.options
  }
}
```

Keep that in mind, might be handy later.

## Working with jobs

When you want to run something on [Nomad][], you normally start with a job.
A job - or rather a job file - is the primary work horse and describes in a declarative way the
tasks you want to run.

Behind the scene, whenever a job is submitted, [Nomad][] evaluates it and determines all necessary
steps for this workload.
Once this is done a new **allocation** is created and scheduled on a client node.,

There are many different object types, but it is probably easier just to start with a concrete
example and explain it line by line as we go:

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
        jvm_options = ["-Xmx256m", "-Xms256m"]
      }

      resources { # <7>
        memory = 256

        network { # <8>
          port "http" {
            static = 8080
          }
        }
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
**<6>** Config options for the chosen task driver. \
**<7>** [Resource limits][] can be set for cpu and memory.. \
**<8>** ..as well as for network and ports. (We need the port definition later)

The next steps assume you've successfully set up and started [Nomad][], if not please have a look
at the [great resources here][].

### How to start a job

There are multiple ways to interact with [Nomad][]:

#### Browser

1. There is a small web-interface available right after start: <http://localhost:4646>

![image](/assets/images/nomad/web.png)

2. After pressing the **Run Job** button in the right upper corner, you can paste your job
definition either in [HCL][] or in [JSON][].

3. The **Plan** button starts a dry-run and [Nomad][] prints the result - which is pretty neat
in comparison to the other options:

![image](/assets/images/nomad/plan_success.png)

4. And a final press on **Run** starts the actual deployment.

![image](/assets/images/nomad/job_success.png)

#### Commandline

For the commandline-savy, there is nice [CLI][] shipped within the same package:

###### **Shell**
```shell
$ nomad job run jobs/todo-java.nomad
==> 2022-07-18T17:48:36+02:00: Monitoring evaluation "2c21d49b"
    2022-07-18T17:48:36+02:00: Evaluation triggered by job "todo-java"
==> 2022-07-18T17:48:37+02:00: Monitoring evaluation "2c21d49b"
    2022-07-18T17:48:37+02:00: Evaluation within deployment: "83abca16"
    2022-07-18T17:48:37+02:00: Allocation "d9ec1c42" created: node "d419df0b", group "web"
    2022-07-18T17:48:37+02:00: Evaluation status changed: "pending" -> "complete"
==> 2022-07-18T17:48:37+02:00: Evaluation "2c21d49b" finished with status "complete"
==> 2022-07-18T17:48:37+02:00: Monitoring deployment "83abca16"
  ✓ Deployment "83abca16" successful

    2022-07-18T17:48:47+02:00
    ID          = 83abca16
    Job ID      = todo-java
    Job Version = 0
    Status      = successful
    Description = Deployment completed successfully

    Deployed
    Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
    web         1        1       1        0          2022-07-18T17:58:46+02:00
```

#### API

And for more hardcore users, you can access the [job API][] with e.g. [curl][] directly:

###### **Shell**
```shell
$ curl --request POST --data @jobs/todo-java.json http://localhost:4646/v1/jobs
{"EvalCreateIndex":228,"EvalID":"bd809b77-e2c6-c336-c5ca-0d1c15ff6cce","Index":228,"JobModifyIndex":228,"KnownLeader":false,"LastContact":0,"NextToken":"","Warnings":""}
```

All three ways send the job to [Nomad][] and start a single instance on clients that belong to the
datacenter aptly named `dc1`.

### Check status of a job

The status of our job can be queried in similar fashion:

###### **Shell**
```shell
$ nomad job status
ID         Type     Priority  Status   Submit Date
todo-java  service  50        running  2022-07-18T17:48:36+02:00
```

Or just use [curl][] to access our services directly:

###### **Shell**
```shell
$ curl -H "Accept: application/json" http://localhost:8080/todo -v
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 8080 (#0)
> GET /todo HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.64.1
> Accept: application/json
>
< HTTP/1.1 204 No Content
<
* Connection #0 to host localhost left intact
* Closing connection 0
```

### Stop jobs again

And without more further ado -  jobs can be stopped like this:

###### **Shell**
```shell
$ nomad job stop todo-java
==> 2022-07-18T18:04:55+02:00: Monitoring evaluation "efe42497"
    2022-07-18T18:04:55+02:00: Evaluation triggered by job "todo-java"
==> 2022-07-18T18:04:56+02:00: Monitoring evaluation "efe42497"
    2022-07-18T18:04:56+02:00: Evaluation within deployment: "577c3e71"
    2022-07-18T18:04:56+02:00: Evaluation status changed: "pending" -> "complete"
==> 2022-07-18T18:04:56+02:00: Evaluation "efe42497" finished with status "complete"
==> 2022-07-18T18:04:56+02:00: Monitoring deployment "577c3e71"
  ✓ Deployment "577c3e71" successful

    2022-07-18T18:04:56+02:00
    ID          = 577c3e71
    Job ID      = todo-java
    Job Version = 2
    Status      = successful
    Description = Deployment completed successfully

    Deployed
    Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
    web         1        1       1        0          2022-07-18T18:12:24+02:00
```

### Advanced topics

So far we have covered the plain basics and we know how to set up, check and stop jobs now.

It is time to talk about the interesting parts now - otherwise the whole comparison with
[Kubernetes][] would be quite pointless.

#### Scaling out

Running only one instance doesn't really justify the use of an orchestrator at all and there
might come a point when you really want to scale out.

If you paid attention to our previous example, you may have noticed there is a `count` parameter
and with it we can easily increase the designed number from e.g. 1 to 5 instances:

###### **HCL**
```hcl
group "web" {
  count = 5
```

When we start another dry-run, [Nomad][] dutiful informs us, that we have port clash and cannot
run five instances on the same port:

![image](/assets/images/nomad/plan_failure.png)

A simple solution here is probably to configure different instances and set a fixed port for each,
but we can also use the [dynamic port][] feature of [Nomad][]:

We first have to remove the static port from our job definition, so it does look like this to let
[Nomad][] pick the ports for us:

###### **HCL**
```hcl
network {
  port "http" {}
```

And secondly we update the driver config to include some of the logic mentioned before in [HCL][]:

###### **HCL**
```hcl
config {
  jar_path = "/Users/christoph.kappel/Projects/showcase-nomad-quarkus/target/showcase-nomad-quarkus-0.1-runner.jar"
  jvm_options = ["-Xmx256m", "-Xms256m", "-Dquarkus.http.port=${NOMAD_PORT_http}"]
}
```

And if we dry-run this again we are greeted with following:

![image](/assets/images/nomad/plan_update.png)

And finally after a press of **Run** with another success and five running instances:

![image](/assets/images/nomad/update_success.png)


#### Load balancing

#### Canary deployments

#### Service discovery


## Conclusion

As always, here is my showcase with some more examples:

<https://github.com/unexist/showcase-nomad-quarkus>

```log
https://learn.hashicorp.com/tutorials/nomad/get-started-intro
https://www.nomadproject.io/api-docs/jobs
https://www.nomadproject.io/docs/internals/plugins/task-drivers
https://github.com/hashicorp/hcl
https://yaml.org/
https://jsonnet.org/
https://docs.dagger.io/1215/what-is-cue/
https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md
https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
https://www.nomadproject.io/docs/job-specification/resources
https://www.nomadproject.io/docs/job-specification/network#dynamic-ports=
```