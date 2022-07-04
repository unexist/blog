---
layout: post
title: Nomad
date: %%%DATE%%%
author: Christoph Kappel
tags: nomad orchestration showcase
categories: showcase
toc: true
---

```log
    2022-06-24T14:05:40.965+0200 [DEBUG] agent.plugin_loader.nomad-driver-podman: http baseurl: plugin_dir=/Users/christoph.kappel/Projects/showcase-nomad-quarkus/deployment/nomad/plugins url=unix://Users/christoph.kappel/.local/share/containers/podman/machine/podman-machine-default/podman.sock @module=podman timestamp="2022-06-24T14:05:40.965+0200"
    2022-06-24T14:05:40.965+0200 [DEBUG] agent.plugin_loader.nomad-driver-podman: http baseurl: plugin_dir=/Users/christoph.kappel/Projects/showcase-nomad-quarkus/deployment/nomad/plugins @module=podman url=unix://Users/christoph.kappel/.local/share/containers/podman/machine/podman-machine-default/podman.sock timestamp="2022-06-24T14:05:40.965+0200"
    2022-06-24T14:05:40.966+0200 [DEBUG] agent.plugin_loader.stdio: received EOF, stopping recv loop: plugin_dir=/Users/christoph.kappel/Projects/showcase-nomad-quarkus/deployment/nomad/plugins err="rpc error: code = Unavailable desc = error reading from server: EOF"
```

```log
  | rpc error: code = Unknown desc = failed to start task, could not create container: unknown error, status code: 500: {"cause":"statfs /Users/christoph.kappel/Projects/showcase-nomad-quarkus/deployment/nomad/data/alloc/23ffe1ac-bc8d-2000-6fae-3b3e452c7f1a/alloc: no such file or directory","message":"statfs /Users/christoph.kappel/Projects/showcase-nomad-quarkus/deployment/nomad/data/alloc/23ffe1ac-bc8d-2000-6fae-3b3e452c7f1a/alloc: no such file or directory","response":500}
  ```

```log