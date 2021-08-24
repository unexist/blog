---
layout: post
title: ADR and jqAssistant
date: 2021-03-15 17:45 +0100
author: Christoph Kappel
tags: tools architecture validation adr showcase
categories: architecture testing showcase
toc: true
---
I've been in a meetup recently and it was about architecture validation with the help of
our good friend [jqAssistant][1]. Although I didn't learn much new in the
first part, the second part was highly interesting:

Combine [ADR][2] with the asciidoc processing of [jqAssistant][1].
I've never thought about it before, but once the speaker presented this idea I was totally into it.

## ADR tools

For a starter, we need to add [AsciiDoc][3] support to the ADR tooling,
since they normally are written in markdown. There is a pending PR that does exactly that:

<https://github.com/npryce/adr-tools/pull/101>

Or if you need a complete set along with other nifty things like indexing a database
(sqlite3) handling and basic atom/rss support, just use my version of it:

<https://github.com/unexist/adr-tools>

Once we've picked our version, we need to set this up accordingly:

###### **Shell:**
```shell
$ adr-tools/adr init -t adoc jqassistant/decisions

$ adr-tools/adr new "Assertion Library"
```

## First steps with jqAssistant

Messing with [jqAssistant][1] is always funny, when you manage to make your mind about [cypher][4],
you are busy with lots of flaky tests and varying output errors, but we'll come to that later I
guess.

I also will not go into detail how to set up jgAssistant or how to create a bootstrap project and
focus on the funny parts. If you want to dive head first just checkout my demo project:

<https://github.com/unexist/showcase-architecture-testing-quarkus>

Back to our new ADR, let us just fill in a bit of magic:

## Revisit our ADR

###### **001-assertion-library.adoc:**
```asciidoc
= 1. Assertion library

|===
| Proposed Date: | 2021-03-15
| Decision Date: | ?
| Proposer:      | Christoph Kappel
| Deciders:      | ?
| Status:        | drafted
| Issues:        | ?
| References:    |
| Priority:      | high
|===

NOTE: *Status types:* drafted | proposed | rejected | accepted | deprecated | superseded +
      *Priority:* low | medium | high

== Context

There are dozen of assertion library available, we want to settle one for
our purpose and rely just on this one.

== Decision

After some consideration we agreed on using https://assertj.github.io/doc/[AssertJ].

== Consequences

[[adr:AssertionLibrary]]
[source,cypher,role=constraint,severity=minor]
.All calls to `assertThat` must be from `AssertJ`!
----
MATCH
      (assertType:Type)-[:DECLARES]->(assertMethod) // <1>
WHERE
      NOT assertType.fqn =~ "org.assertj.core.api.*" // <2>
            AND assertMethod.signature =~ ".*assertThat.*"
WITH
      assertMethod
MATCH
      (testType:Type)-[:DECLARES]->(testMethod:Method),
      (testMethod)-[invocation:INVOKES]->(assertMethod)
RETURN
      testType.fqn + "#" + testMethod.name as TestMethod, // <3>
      invocation.lineNumber as LineNumber
ORDER BY
      TestMethod, LineNumber
----

include::jQA:Rules[concepts="adr:AssertionLibrary*", constraints="adr:AssertionLibrary*"] // <4>
```

So this is basically the complete ADR and I assume most of the things beside the weird code block
is pretty self explanatory.
The code block - glad you've asked - is cypher.

It creates a simple query **<1>** for all methods, that have `assertThat` in its method signature
and then checks, if the full-qualified name of the package is NOT `org.assertj.core.api`. **<2>**
For every match **<3>**, it returns the name of the method, along with its line number.

When this list is empty the test passes, if not you'll get a neat nice table below the definition
in the output.

NOTE: The part around **<4>** is required to see the actual results in the rendered document, took
      me quite a whole to figure this out.

## Put it to the test in jqAssistant

So we have to jump right back to [jqAssistant][1], since we are done with the ADR.

Next best thing to do is to create an `index.adoc` document for jqAssistant to render:

###### **index.adoc:**
```asciidoc
:description: This is a demo project for the combination of ADR and jqAssistant.
:doctype: book
:toc: left
:toc-title: Table of Contents
:toclevels: 2
:sectnums:
:icons: font
:nofooter:

[[default]] // <1>
[role=group,includesGroups="adr:default"]
== Architecture decisions, tests and metrics

This document contains example https://jqassistant.org/[jqAssistant] rules
along with simple https://adr.github.io/[Architecture Decision Records].

[[adr:default]]
[role=group,includesConcepts="adr:*",includesConstraints="adr:*"] // <2>
== List of Architecture Decision Records

include::decisions/0001-assertion-library.adoc[leveloffset=2] // <3>
```

The default group **<1>** is **required**, otherwise jqAssistant will not pick up this document
and render nothing at all.

The remaining points, namely **<2>** and **<3>**, include the ADR into our main document.

## Conclusion

Both tools can be used to write tests for architecture. The addition of a graph database in
[jqAssistant][1] along with the query language [Cypher][4] and the different input plugins allow
more flexibility, but also set a steep learning curve.

My showcase can be found here:

<https://github.com/unexist/showcase-architecture-testing-quarkus>

[1]: https://jqassistant.org
[2]: https://adr.github.io/
[3]: https://asciidoc.org/
[4]: https://neo4j.com/developer/cypher/