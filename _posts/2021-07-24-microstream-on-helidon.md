---
layout: post
title: Microstream on Helidon
date: 2021-07-24 17:01 +0200
author: Christoph Kappel
tags: tools microstream helidon showcase
categories: tech showcase frameworks
---
Someone at work recently asked the crowd, if there are any experience at all with [MicroStream][1]
without success. And I also must admit at this point I've never even heard about it.

I digged into it and apparently they are working hand-in-hand with the developers of the
[Helidon][2] project to integrate it into it:

<https://microstream.one/resources/blog/article/microstream-will-be-integrated-with-helidon>

I briefly touched [Helidon][2] in previous experiment, after reading about it for the first time in
[this book][3] about [domain-driven design][4], but never created a complete showcase. It's about
time to change this and delve into [Helidon][2] once again.

## Helidon

[Helidon][2] actually comes in two flavors, but we will focus on the [MicroProfile][5] or just `MP`
version of it. The [documentation][6] is fairly good and with the provided archetypes the first
steps are made quickly.

Since I wanted to integrate this into my usual kata, I basically took my todo example and just
added [Helidon][2] to it.

### How to successfully compile it?

Let us start with the easy problems: The [Helidon CLI][7] cannot find the main class:

#### **Log**:
```log
Helidon project is not supported: The required 'mainClass' property is missing.
```

During my research I've found many projects that defined their own, but apparently all it takes is
this:

#### **pom.xml**:
```xml
<properties>
    <mainClass>io.helidon.microprofile.cdi.Main</mainClass>
</properties>
```

### How to actually start it?

[Helidon][2] also comes with [Helidon CLI][7], that can start the application and then continuously
watches files for changes and restarts when necessary - the so called `devloop`.

On my first try I was greeted with a really cryptic error message:

#### **Log**:
```log
loop failed helidon-cli-maven-plugin must be configured as an extension
```

After a bit of a try out and some more googling I finally narrowed it down and it is really just a
configuration problem coupled with my lack of knowledge how [Maven][7] extensions are supposed to
work:

#### **pom.xml**:
```xml
<plugin>
    <groupId>io.helidon.build-tools</groupId>
    <artifactId>helidon-cli-maven-plugin</artifactId>
    <version>${helidon-cli-plugin.version}</version>
    <extensions>true</extensions> <!-- 1 -->
</plugin
```

**<1>**: This is all that is required.

Once I got the `devloop` running the startup and also the reload after a change runs flawlessly
most of the time.

### No beans found?

Unfortunately, [Helidon][2] refused to pick any [JAX-RS][9] applications and I found this goodie here
in my application log:

#### **Log**:
```log
There are no JAX-RS applications or resources. Maybe you forgot META-INF/beans.xml file?"
```

Looks like I am kind of spoiled by [Quarkus][10], because it really took me a while to understand
what is going on here. Alas, the solution is quite easy - I just had to configure [Jandex][11]
properly:

#### **pom.xml**:
```xml
<plugin>
    <groupId>org.jboss.jandex</groupId>
    <artifactId>jandex-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>make-index</id>
            <goals>
                <goal>jandex</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### No handler found for path?

Almost there - just another tiny problem: [Helidon][2] seems to ignore all resources and also my
`microprofile-config.properties` file completely. This results into:

#### **Log**:
```log
No handler found for path: /todo
```

This was kind of tough to fix, my code looked pretty similar to the examples that I have found and
that I could generate with the [archetypes][12].

Although the examples just included `helidon-dependencies`, I also had to include `helidon-bom` to
get this working:

#### **pom.xml**:
```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>io.helidon</groupId>
            <artifactId>helidon-bom</artifactId>
            <version>${helidon.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <dependency>
            <groupId>io.helidon</groupId>
            <artifactId>helidon-dependencies</artifactId>
            <version>${helidon.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

## MicroStream

After all the problems with [Helidon][2] it is a weird surprise, that there is no currently usable
support of [MicroStream][1] right now. Still - sticking to the original plan, let es see what it is
all about. Citation time:

> Realize ultra-fast in-memory data processing with pure Java. Microsecond query time. Low-latency
data access. Gigantic data throughput and workloads. Save lots of CPU power, CO2 emission, and
costs in the data center.
<cite>https://microstream.one/platforms/microstream-for-java/</cite>

Between all of this marketing blabla, there are still some interesting properties. Let me try to
explain it in my own words:

[MicroStream][1] basically allows you to store and retrieve any kind of custom data at a given path.
And since it basically retrieves the complete structure for you, there is no need for any kind of
special [query][13] language; all basic operations, filters and so on still work.

If you want to store deep and nested data there is neat trick, [lazy loading][14] can be used here
so it is just retrieved when really necessary. My current example doesn't realy makes use of it,
but the examples clearly state how this can be done and what the obvious advantage of it is.

### Getting started

Getting started is really easy and since the latest release `05.00.02-MS-GA` its even directly
available from [Maven][8]. So since I cannot describe it any better:

<https://docs.microstream.one/manual/storage/getting-started.html>

## Conclusion

So this is combined post for two things, which I thought would work nicely along each other.
Unfortunately, there is still some way to go this combination.

[Helidon][2] is pretty fast and once you really fixed some the initial problems adding features is
pretty straight forward. There is a huge list of extensions and I am eager to test it in a real
scenario.

[MicroStream][1] is also really interesting, since you basically define the structure, the handling
is pretty easy and there is no additional set up required, like for any other database. I currently
don't have any ideas how to really make use of it, but I will surely keep it in the back of my mind.

My showcase can be found here:

<https://github.com/unexist/showcase-microstream-helidon>

[1]: https://microstream.one/
[2]: https://helidon.io
[3]: https://www.amazon.com/dp/1484245423
[4]: https://en.wikipedia.org/wiki/Domain-driven_design
[5]: https://microprofile.io/
[6]: https://helidon.io/docs/latest/#/mp/introduction/01_introduction
[7]: https://medium.com/helidon/the-new-helidon-cli-cd90bc4a0d1a
[8]: https://maven.apache.org/
[9]: https://github.com/jax-rs
[10]: https://quarkus.io
[11]: https://github.com/wildfly/jandex-maven-plugin
[12]: https://mvnrepository.com/artifact/io.helidon.archetypes
[13]: https://docs.microstream.one/manual/storage/queries.html
[14]: https://docs.microstream.one/manual/storage/loading-data/lazy-loading/index.html
[15]: https://docs.microstream.one/manual/storage/getting-started.html