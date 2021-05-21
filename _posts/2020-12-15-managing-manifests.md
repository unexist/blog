---
layout: post
title: Managing manifests
date: 2020-12-15 16:53 +0100
author: Christoph Kappel
tags: tools kubernetes ansible make helm helmfile to-be-continued
---
Starting with [kubernetes](https://kubernetes.io/) can be funny, especially when you finally
understand a bit more about the internals and how to use all those manifests and objects.

After my first few steps and mistakes, which basically lead to a complete re-setup of my
[kind](https://kind.sigs.k8s.io/docs/user/quick-start/) cluster, I decided I want to find a
proper way to manage the configs.

I found support for [kubernetes](https://kubernetes.io/) manifests in ansible, which a good friend
of mine is fond of, so I gave it a spin.

Ansible
====
The installation of [ansible](https://www.ansible.com/) itself and the galaxy plugin is pretty
straight forward and better explained
[here](https://docs.ansible.com/ansible/latest/collections/community/kubernetes/k8s_module.html),
than I ever could.

That out of the way, let us see how it actually works. Written in [python](https://www.python.org/),
it uses  [jinja2](https://docs.ansible.com/ansible/latest/user_guide/playbooks_templating.html) for
templating, which looks awfully familiar (and yes, I copied the first example):

#### **random.yaml:**
```yaml
- name: Create a k8s namespace
  community.kubernetes.k8s:
    name: testing
    api_version: v1
    kind: Namespace
    state: present
```

This basically let's us rewrite or rather copy the whole manifests and put them into playbooks,
there is bit of template magic available, but I don't see any really advantage here. Next!

Make
====
Using good ol' [make](https://www.gnu.org/software/make/manual/make.html) should be sufficient
here, right? We just apply a bunch of yaml files and can define dependencies to targets, this
should make it pretty worthwhile.

After some hours fighting multiline commands and a complete lack of any heredoc, I assembled some
simple targets, which basically consisted of ```kubectl apply -f deployment/file.yaml``` or the
reversal of it with **delete**.

During my time with make, I had a few learnings along the way:

* Setting variables inside of targets is difficult and can only be done via: ```$(eval VAR := $(shell ls))```
* Default targets can be set like this: ```.DEFAULT_GOAL := target```
* Use **.PHONY**, when the name of the target is also a directory: ```.PHONY: docs```

I used this for a while, but.. NEXT!

Helm
====
[Helm](https://helm.sh/) is another way of managing your resources. Behind the nautical-themed
name is a full-featured repository manager and a powerful templating engine, which I mentioned
earlier looks pretty similar to [jinja2](https://jinja.palletsprojects.com/en/2.11.x/)

So you can either use one of the many ready-to-use charts from a chart museum - that is the name
of the repositories (still nautical - you see?) or roll your own. There is lots of ground to cover
and I don't want to even try to give a glimpse into it, there are dozen of better resources
available.

Library type
----
Still one noteworthy thing is the new library type in v3 of helm: They allow us to create
non-installable base charts and let new charts inherit from. This way you don't have to copy/paste
manifests and can just include them from a base.

This is pretty straight forward, here is a small example:

### Layout

The layout can be like this:

```shell
$ ls -R1 base-chart
 Chart.yaml
 templates/

base-chart/templates:
  _deployment.tpl
  _helpers.tpl
  _service.tpl
```

```shell
$ ls -R1 inherited-chart
  Chart.yaml
  templates/
  values.yaml

inherited-chart/templates:
  _helpers.tpl
  deployment.yaml
  service.yaml
```

### Contents

And the content of files can be like this:

#### **base-chart/templates/_service.tpl:**
```yaml
{{- define "base-chart.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "base-chart.fullname" . }}
  labels:
    {{- include "base-chart.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.container.port }}
      protocol: TCP
      name: http
  selector:
    {{- include "base-chart.selectorLabels" . | nindent 4 }}
{{- end -}}
```

#### **`inherited-chart/templates/service.yaml`:**
```yaml
{{ include "base-chart.service" . }}
```

## Managing kubernetes

So back to the task at hand, I wanted to manage a complete set up and with [Helm](https://helm.sh/)
I can create a bunch of charts to install them and manage the versions.

## Umbrella charts

And to makle this easier: We can create a so-called umbrella chart, which just consists of
dependencies to other charts and install them accordingly.

# Helmfile

[Helmfile](https://github.com/roboll/helmfile) is another layer on-top of [Helm](https://helm.sh/)
and makes the whole handling a bit easier. Once you've created a helm chart, you can take the
*values file* from it and use the remaining chart as a template for the rest.

For new deployments, you just create a new *values file* and let
[Helmfile](https://github.com/roboll/helmfile) handle the rest.

## Layout

A simple layout can be like this:

```shell
$ ls -R1 helmfile
 helmfile.yaml

charts:
 base-chart/

charts/base-chart/
# snip

environments:
 default.yaml

values:
inherited.yaml
```

The usage of environments is a bit tricky, but I will explain it down the road. So let us focus on
the *helmfile*, which contains all the fun:

#### **helmfile.yaml:**
```yaml
repositories:
  - name: stable
    url: https://charts.helm.sh/stable

releases:
  - name: inherited
    chart: ./charts/base-chart
    #needs:
    #- other_chart
    values:
      - ./values/inherited.yaml
```

Here we describe a single release, with no other dependencies (needs), which uses the our
**base-chart** as a base and its values from a file named **inherited.yaml**. With this ready,
a single run of ```helmfile sync``` should do the trick.

## Environments

Environments offer a way to set stuff like ports, credentials and stuff like that for a complete
env - so you don't have to use different versions here.

### environments/default.yaml

Here we define the username and password for a postgress database_

```yaml
postgres:
  username: test
  password: test
```

In order to use this config, we have to rename **inherited.yaml** to **inherited.tpl**:

#### **values/inherited.tpl:**
```yaml
# snip
  config:
    - key: POSTGRES_USER
      value: {{ .Environment.Values.postgres.username }}
    - key: POSTGRES_PASSWORD
      value: {{ .Environment.Values.postgres.password }}
# snip
```