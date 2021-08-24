---
layout: post
title: AsciiDoctor, Maven and IntelliJ
date: 2021-04-29 17:37 +0200
author: Christoph Kappel
tags: tools intellij maven asciidoc
categories: tech
toc: true
---
[AsciiDoc][1] is one of my favorite text processors for anything related to **Documentation-as-Code**.

I use it quite excessively in my current project, for documentation on service level but also for
architecture documentation based on [ARC42][2].
(If you really want to look into it I suggest to have a look at the documentation
[Asciidoc Writer's Guide][3].

It is as convenient as [Markdown][4] and has a few other tricks up its sleeve like support for
images and a proper way to use a hierarchy of documents. The only thing that kind of annoys me
is the import idiocy - a few of you probably know from [PHP][5]:

If you include something from a subdirectory, all other other includes are relative
to this new root now. This leads to interesting issues, especially if you want to deal with images.

## Images

One of the few things that you commonly see is basically to prefix every image include with the
**:imagedir:** attribute:

###### **random.adoc**
```adoc
:imagedir: ./images
image::foobar.png[caption=Test]
```

This leads to lots of redundancy and makes a change of this quite nasty, once you are dealing
with a large document.

## Maven

When you are using [maven][6], there is another way just to set the
**imagedir** attribute inside of your [pom][7]:

###### **pom.xml:**
```xml
<plugin>
    <groupId>org.asciidoctor</groupId>
    <artifactId>asciidoctor-maven-plugin</artifactId>
    <version>${asciidoctor.maven.plugin.version}</version>

    <configuration>
        <attributes>
            <imagesdir>./images</imagesdir>
        </attributes>
    </configuration>
</plugin>
```

## IntelliJ

There seems to be some kind of unwritten rule, that [IntelliJ][8] **always** has to fail for
something that works quite nicely with [maven][6] even when you install the [asciidoc plugin][9] -
so no surprises here.

After some digging around, I discovered [this config file][10]:

The plugin supports the usage of a config file, that can be placed in the root level of your
document and gets prefixed automatically to every [AsciiDoc][1] file that
is below this paths:

###### **.asciidoctorconfig:**
```adoc
:icons: font
:imagesdir: {asciidoctorconfigdir}/images
```

[1]: https://asciidoctor.org/
[2]: https://arc42.org/
[3]: https://asciidoctor.org/docs/asciidoc-writers-guide/
[4]: https://daringfireball.net/projects/markdown/
[5]: https://www.php.net/
[6]: https://maven.apache.org/
[7]: https://maven.apache.org/pom.html
[8]: https://www.jetbrains.com/idea/
[9]: https://plugins.jetbrains.com/plugin/7391-asciidoc
[10]: https://intellij-asciidoc-plugin.ahus1.de/docs/users-guide/features/advanced/asciidoctorconfig-file.html