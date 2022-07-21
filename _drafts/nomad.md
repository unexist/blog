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

There is an exhaustive list of provided task drivers like [Docker][], [Java][] or [raw/exec][]) to
name a few and some of them are community-driven.
Docs [how to provide new ones][] are also available, so expect this list to grow even further.

Before we can start playing with the actual objects, we have to talk about configuration.

## Configuration without YAML

By design, [Kubernetes][] follows a [declarative approach][] and allows to specify the desired
outcome of your objects in a [YAML][] file.
If you want to change something programmatically or even parameterize you can either use the API
directly and patch your objects or rely on tools like [helm][] or [kustomize][].

[Nomad][] follows a similar approach, but utilizes [HashiCorp][]'s own configuration language
[HCL][], which was initially introduced for [Terraform][] to add logic to the mix without the
syntactic weirdness of [jsonnet][] or [Docker][]'s [CUE][].

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

Keep that in mind, this might be handy later.

## Working with jobs

When you want to run something on [Nomad][], you normally start with a [job][].
A [job][] - or rather a job file - is the primary work horse and describes in a declarative way the
tasks you want to run.

Behind the scene, whenever a [job][] is submitted, [Nomad][] starts with an [evaluation][] to
determine necessary steps for this workload.
Once this is done, [Nomad][] maps this [job][]  a new [allocation][] is created - this is basically a mapping of a job to and scheduled on a client node.

There are many different object types, but it is probably easier just to start with a concrete
example and explain it line by line as we go:

###### **HCL**
```hcl
job "todo" {
  datacenters = ["dc1"] # <1>

  group "web" { # <2>
    count = 1 # <3>

    task "todo" { # <4>
      driver = "java" # <5>

      config { # <6>
        jar_path = "/Users/christoph.kappel/Projects/showcase-nomad-quarkus/target/showcase-nomad-quarkus-0.1-runner.jar"
        jvm_options = ["-Xmx256m", "-Xms256m"]
      }

      resources { # <7>
        memory = 256
      }
    }

    network { # <8>
      port "http" {
        static = 8080
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
**<7>** [Resource limits][] can be set for cpu and memory. \
**<8>** And additionally network settings for the whole task-group.
 (We need the port definition later)

The next steps assume you've successfully set up and started [Nomad][], if not please have a look
at the [great resources here][].

### How to start a job

There are multiple ways to interact with [Nomad][]:

#### Browser

1. There is a small web-interface available right after start: <http://localhost:4646>

![image](/assets/images/nomad/web.png)

2. After pressing the **Run Job** button in the right upper corner, you can paste your [job][]
definition either in [HCL][] or in [JSON][].

3. The **Plan** button starts a dry-run and [Nomad][] prints the result:

![image](/assets/images/nomad/plan_success.png)

4. And a final press on **Run** starts the actual deployment.

![image](/assets/images/nomad/job_success.png)

#### Commandline

For the commandline-savy, there is nice [CLI][] shipped within the same package:

###### **Shell**
```shell
$ nomad job plan jobs/todo-java.nomad
+ Job: "todo"
+ Task Group: "web" (1 create)
  + Task: "todo" (forces create)

Scheduler dry-run:
- All tasks successfully allocated.

$ nomad job run jobs/todo-java.nomad
==> 2022-07-18T17:48:36+02:00: Monitoring evaluation "2c21d49b"
    2022-07-18T17:48:36+02:00: Evaluation triggered by job "todo"
==> 2022-07-18T17:48:37+02:00: Monitoring evaluation "2c21d49b"
    2022-07-18T17:48:37+02:00: Evaluation within deployment: "83abca16"
    2022-07-18T17:48:37+02:00: Allocation "d9ec1c42" created: node "d419df0b", group "web"
    2022-07-18T17:48:37+02:00: Evaluation status changed: "pending" -> "complete"
==> 2022-07-18T17:48:37+02:00: Evaluation "2c21d49b" finished with status "complete"
==> 2022-07-18T17:48:37+02:00: Monitoring deployment "83abca16"
  ✓ Deployment "83abca16" successful

    2022-07-18T17:48:47+02:00
    ID          = 83abca16
    Job ID      = todo
    Job Version = 0
    Status      = successful
    Description = Deployment completed successfully

    Deployed
    Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
    web         1        1       1        0          2022-07-18T17:58:46+02:00
```

#### API

More hardcore users can also access the [job API][] with e.g. [curl][] directly:

###### **Shell**
```shell
$ curl --request POST --data @jobs/todo-java.json http://localhost:4646/v1/jobs
{"EvalCreateIndex":228,"EvalID":"bd809b77-e2c6-c336-c5ca-0d1c15ff6cce","Index":228,"JobModifyIndex":228,"KnownLeader":false,"LastContact":0,"NextToken":"","Warnings":""}
```

**Note**: You can find the example in JSON here: <https://github.com/unexist/showcase-nomad-quarkus/blob/master/deployment/jobs/todo-java.json>

All three ways send the [job][] to [Nomad][] and start a single instance on clients that belong to
the datacenter aptly named `dc1`.

### Check status of a job

The status of our [job][] can be queried in similar fashion:

###### **Shell**
```shell
$ nomad job status
ID    Type     Priority  Status   Submit Date
todo  service  50        running  2022-07-18T17:48:36+02:00
```

Or just use [curl][] to access our services directly:

###### **Shell**
```shell
$ curl -v -H "Accept: application/json" http://localhost:8080/todo
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

And without more further ado -  [jobs][] can be stopped like this:

###### **Shell**
```shell
$ nomad job stop todo
==> 2022-07-18T18:04:55+02:00: Monitoring evaluation "efe42497"
    2022-07-18T18:04:55+02:00: Evaluation triggered by job "todo"
==> 2022-07-18T18:04:56+02:00: Monitoring evaluation "efe42497"
    2022-07-18T18:04:56+02:00: Evaluation within deployment: "577c3e71"
    2022-07-18T18:04:56+02:00: Evaluation status changed: "pending" -> "complete"
==> 2022-07-18T18:04:56+02:00: Evaluation "efe42497" finished with status "complete"
==> 2022-07-18T18:04:56+02:00: Monitoring deployment "577c3e71"
  ✓ Deployment "577c3e71" successful

    2022-07-18T18:04:56+02:00
    ID          = 577c3e71
    Job ID      = todo
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
and with it we can easily increase the designated number from e.g. 1 to 5 instances:

###### **HCL**
```hcl
group "web" {
  count = 5
```

When we start another dry-run, [Nomad][] dutiful informs us, that we have port clash and cannot
run five instances on the same port:

![image](/assets/images/nomad/plan_failure.png)

A simple solution here is to configure different instances and set a fixed port for each, but we
can also use the [dynamic port][] feature of [Nomad][]:

We first have to remove the static port number from our [job][] definition - by basically removing
the configuration and force [Nomad][] to ports for us now:

###### **HCL**
```hcl
network {
  port "http" {}
}
```

Secondly, we update the driver config to include some of the logic mentioned before in [HCL][]:

###### **HCL**
```hcl
config {
  jar_path = "/Users/christoph.kappel/Projects/showcase-nomad-quarkus/target/showcase-nomad-quarkus-0.1-runner.jar"
  jvm_options = [
    "-Xmx256m", "-Xms256m",
    "-Dquarkus.http.port=${NOMAD_PORT_http}" # <1>
  ]
}
```

**<1>** This is a magic variable of [Nomad][] to assign a dynamic port to [Quarkus][].

And if we dry-run this again we are greeted with following:

![image](/assets/images/nomad/plan_update_scale.png)

After final press of **Run** we can see another success and five running instances after a few
seconds:

![image](/assets/images/nomad/update_success.png)

Normally, our next step should be to install some kind of load balancer, add ports and addresses
of our instances to it and call it a day.
This involves lots of manual tasks and also invites problems like changes of addresses and/or ports,
whenever [Nomad][] has to make a new allocation for an instance.

Alas, this is pretty common problem and already solved for us.

#### Service discovery

[Service discovery][] is basically a central catalog and every interested service can register
itself and fetch information about other registered services.

Our best pick from the many options is [Consul][], another product from [HashiCorp][], with an
obviously pretty good integration.

We can facilitate [Nomad][]'s [artifact][] stanza in combination with the [raw/exec][] task driver
to fetch [Consul][] and run it directly from the internet:

###### **HCL**
```hcl
job "consul" {
  datacenters = ["dc1"]

  group "consul" {
    count = 1

    task "consul" {
      driver = "raw_exec" # <1>

      config {
        command = "consul"
        args    = ["agent", "-dev"]
      }

      artifact { # <2>
        source = "https://releases.hashicorp.com/consul/1.12.3/consul_1.12.3_darwin_amd64.zip"
      }
    }
  }
}
```

**<1>** Here we selected the [raw/exec][] task driver. \
**<2>** This defines the source for the [artifact][] we want to execute.

The deployment is pretty much self-explanatory:

###### **Shell**
```shell
$ nomad job run jobs/consul.nomad
==> 2022-07-20T12:15:24+02:00: Monitoring evaluation "eb0330c5"
    2022-07-20T12:15:24+02:00: Evaluation triggered by job "consul"
    2022-07-20T12:15:24+02:00: Evaluation within deployment: "c16677f8"
    2022-07-20T12:15:24+02:00: Allocation "7d9626b8" created: node "68168a84", group "consul"
    2022-07-20T12:15:24+02:00: Evaluation status changed: "pending" -> "complete"
==> 2022-07-20T12:15:24+02:00: Evaluation "eb0330c5" finished with status "complete"
==> 2022-07-20T12:15:24+02:00: Monitoring deployment "c16677f8"
  ✓ Deployment "c16677f8" successful

    2022-07-20T12:15:36+02:00
    ID          = c16677f8
    Job ID      = consul
    Job Version = 0
    Status      = successful
    Description = Deployment completed successfully

    Deployed
    Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
    consul      1        1       1        0          2022-07-20T12:25:34+02:00
```

After a few seconds [Consul][] is ready and we can have a look at its web-interface at
<http://localhost:8500>:

![image](/assets/images/nomad/consul_services_nomad.png)

The service tab shows all currently registered services and we can already see that [Nomad][] and
[Consul][] are automatically registered and listed.

In order for our services to appear, we need to add the [service][] stanza to our example:

###### **HCL**
```hcl
service {
  name = "todo"
  port = "http"

  tags = [
    "urlprefix-/todo", # <1>
  ]

  check { # <2>
    type     = "http"
    path     = "/"
    interval = "2s"
    timeout  = "2s"
  }
}
```

**<1>** [Nomad][] allows to set tags to service - we need this specific tag in the next section. \
**<2>** The [check][] stanza describes how [Nomad][] shall check, if this service is healthy.

A quick check after our modification of the [job][]:

![image](/assets/images/nomad/plan_update_service.png)



![image](/assets/images/nomad/consul_services_todo.png)

#### Load balancing

###### **HCL**
```hcl
job "fabio" {
  datacenters = ["dc1"]

  group "fabio" {
    count = 1

    task "fabio" {
      driver = "raw_exec"
      config {
        command = "fabio"
        args    = ["-proxy.strategy=rr"] # <1>
      }
      artifact {
        source      = "https://github.com/fabiolb/fabio/releases/download/v1.6.1/fabio-1.6.1-darwin_amd64"
        destination = "local/fabio"
        mode        = "file"
      }
    }
  }
}
```

###### **Shell**
```shell
nomad job run jobs/fabio.nomad
==> 2022-07-19T15:53:33+02:00: Monitoring evaluation "eb13753c"
    2022-07-19T15:53:33+02:00: Evaluation triggered by job "fabio"
    2022-07-19T15:53:33+02:00: Allocation "d923c41d" created: node "dd051c02", group "fabio"
==> 2022-07-19T15:53:34+02:00: Monitoring evaluation "eb13753c"
    2022-07-19T15:53:34+02:00: Evaluation within deployment: "2c0db725"
    2022-07-19T15:53:34+02:00: Evaluation status changed: "pending" -> "complete"
==> 2022-07-19T15:53:34+02:00: Evaluation "eb13753c" finished with status "complete"
==> 2022-07-19T15:53:34+02:00: Monitoring deployment "2c0db725"
  ✓ Deployment "2c0db725" successful

    2022-07-19T15:53:46+02:00
    ID          = 2c0db725
    Job ID      = fabio
    Job Version = 0
    Status      = successful
    Description = Deployment completed successfully

    Deployed
    Task Group  Desired  Placed  Healthy  Unhealthy  Progress Deadline
    fabio       1        1       1        0          2022-07-19T16:03:45+02:00
```

![image](/assets/images/nomad/consul_services_fabio.png)

###### **HCL**
```hcl
config { # <6>
  jar_path = "/Users/christoph.kappel/Projects/showcase-nomad-quarkus/target/showcase-nomad-quarkus-0.1-runner.jar"
  jvm_options = [
    "-Xmx256m", "-Xms256m",
    "-Dquarkus.http.port=${NOMAD_PORT_http}",
    "-Dquarkus.http.header.TodoServer.value=${NOMAD_IP_http}:${NOMAD_PORT_http}",
    "-Dquarkus.http.header.TodoServer.path=/todo",
    "-Dquarkus.http.header.TodoServer.methods=GET"
  ]
}
```

![image](/assets/images/nomad/loadbalancer.gif)

#### Update strategies

- Rolling upgrades
- Blue/green deployments
- Canary deployments

###### **HCL**
```hcl
update {
  canary       = 1
  max_parallel = 5
}
```

![image](/assets/images/nomad/plan_update_canary.png)

![image](/assets/images/nomad/promote_canary.png)


## Conclusion

As always, here is my showcase with some more examples:

<https://github.com/unexist/showcase-nomad-quarkus>

```log
https://learn.hashicorp.com/tutorials/nomad/get-started-intro
https://www.nomadproject.io/api-docs/jobs
https://www.nomadproject.io/docs/internals/plugins/task-drivers
https://www.nomadproject.io/docs/drivers/raw_exec
https://github.com/hashicorp/hcl
https://yaml.org/
https://jsonnet.org/
https://docs.dagger.io/1215/what-is-cue/
https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md
https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/
https://www.nomadproject.io/docs/job-specification/job
https://www.nomadproject.io/docs/job-specification/resources
https://www.nomadproject.io/docs/job-specification/service
https://www.nomadproject.io/docs/job-specification/update
https://www.nomadproject.io/docs/job-specification/network#dynamic-ports=
https://github.com/unexist/showcase-nomad-quarkus/blob/master/deployment/jobs/todo-java.json
https://fabiolb.net/
https://www.consul.io/
```