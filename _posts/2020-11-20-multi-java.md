---
layout: post
title: Multi java
date: 2020-11-20 17:01 +0100
author: Christoph Kappel
tags: tools java jenv macos
categories: tech
---
There are many difficulties with Java, specially if you have to use multiple versions on
your machine like you usual have to. Coming from Debian, this was quite easy with the
alternative mechanisms, but on macOS?

# Welcome jenv!

[Jenv][1] is a kind of package manager for all your Java versions, which helps you to switch
between each of them pretty nicely, once you've set it up correctly.

Installation is as easy as open a cold one:

#### **Shell:**
```shell
$ brew install jenv
```

*Once done, it reminds you to add it to your shell rc, which is probably a good idea.*

Quick side note: Make sure to create the proper directories too, otherwise the commands fail
in a weird way:

#### **Shell:**
```shell
$ mkdir -p ~/.jenv/version
```

# One java to go

The easiest way to see your installed Java version sis via the **java_home** command:

#### **Shell:**
```shell
$ /usr/libexec/java_home -V
Matching Java Virtual Machines (1):
    1.8.0_201, x86_64:	"Java SE 8"	/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home
```

So far, nothing much to switch, but we still want to add it to [Jenv][1]:

#### **Shell:**
```shell
$ jenv add /Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home

oracle64-1.8.0.201 added
1.8.0.201 added
1.8 added
```

A quick look into **~/.jenv/versions** to check, that it basically created some symlinks to your
installation.

# Make it two

There is still not much to do, for a Java version manager, when there is only one version. Time
to install another one, this time [AdoptOpenJdk][2]:

#### **Shell:**
```shell
$ brew cask install adoptopenjdk
$ brew cask install adoptopenjdk11
```

And another command to add it to [Jenv][1]:

#### **Shell:**
```shell
$ jenv add /Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home

openjdk64-11.0.9.1 added
11.0.9.1 added
11.0 added
11 added
```

# Versions?

Now we have to versions installed, let's check it:

#### **Shell:**
```shell
$ jenv versions
* system (set by /Users/unexist/.jenv/version)
  openjdk64-11.0.9.1
  oracle64-1.8.0.201
```

And what about **java_home**:

#### **Shell:**
```shell
$ /usr/libexec/java_home -V
Matching Java Virtual Machines (2):
    11.0.9.1, x86_64:	"AdoptOpenJDK 11"	/Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home
    1.8.0_201, x86_64:	"Java SE 8"	/Library/Java/JavaVirtualMachines/jdk1.8.0_201.jdk/Contents/Home
```

# How to use jenv?

All set up done, we can now do the following:

## Set a java version

This can be done like this:

#### **Shell:**
```shell
$ jenv global openjdk64-11.0.9.1
```

And verified like:

#### **Shell:**
```shell
$ jenv versions
  system
  1.8
  1.8.0.201
  11
  11.0
  11.0.9.1
* openjdk64-11.0.9.1 (set by /Users/unexist/.jenv/version)
  oracle64-1.8.0.201
```

[1]: https://www.jenv.be/
[2]: https://adoptopenjdk.net/