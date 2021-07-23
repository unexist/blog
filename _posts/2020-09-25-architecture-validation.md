---
layout: post
title: Architecture validation
date: 2020-09-25 11:00:00 +0200
author: Christoph Kappel
tags: tools architecture validation ddd showcase
categories: architecture
---
Over the last few days I played with tool-based architecture validation, to give colleagues a basic
introduction to the whole topic.

I tested [ArchUnit][1] and [jqAssistant][2] and skipped anything, that isn't fit to be included
into a build pipeline.

Just for completeness: There are other well-known tools like [Structure101][3] or [Sotograph][4]
commercially available, for deeper analysis of a given architecture.

## ArchUnit

This framework comes with a really nice fluent API, which allows you to easily create your own
testcases and after a bit of initial try/error, it is pretty clear how to roll.

For example, this rule checks, if methods in the package named *test* are public:

#### **test.java:**
```java
@ArchTest
static final ArchRule checkPlacement =
    classes()
        .that()
            .resideInAnyPackage("..test..")
        .should()
            .bePublic();
```

Overall, this API is quite powerful and there quite a few plugins to enhance the impressive set. So
in other words, it is always a good idea to check, if someone already solved the problem for you.

So besides simple stuff like the above, architects are probably more interested in rules, that
enforce a given layout or rather architecture.

One of the better known architecture - the layered architecture - can be checked nicely:

#### **test.java:**
```java
private final JavaClasses classes = new ClassFileImporter().importPackages("dev.unexist");

@Test
public void testLayeredArch() {
    layeredArchitecture()
            .layer("Application")
            .definedBy("..application..")
        .layer("Model")
            .definedBy("..model..")
        .layer("Service")
            .definedBy("..service..")
            .layer("Repository")
            .definedBy("..repository..")
        .layer("Infrastructure")
            .definedBy("..infrastructure..")

        .whereLayer("Application")
            .mayNotBeAccessedByAnyLayer()
        .whereLayer("Service")
            .mayOnlyBeAccessedByLayers("Application")
        .whereLayer("Model")
            .mayOnlyBeAccessedByLayers("Application", "Service", "Repository")
        .whereLayer("Repository")
            .mayOnlyBeAccessedByLayers("Service")
        .whereLayer("Infrastructure")
            .mayOnlyBeAccessedByLayers("Service")
        .check(classes);
}
```

These rules define different layers and specify the allowed interaction between each other.

## jqAssistant

In comparison to [ArchUnit][1], this framework uses a different approach
and can be broken down into three step/components:

### Scanner/Analyzer

The combination of both scans the given source tree, analyzed the types, relations and so on and
stores all learnings into the graph database.

### Graph database ([Neo4j][5])

Once data is in the database, it can be queried e.g. via fancy frontends like [Neo4j browser][6].

### Query/Constraint checker

And lastly, the selected query language ([Cypher][7] is the default here) can be used to describe either
queries to get infos, to formalize concepts or constraints.

Concepts are kind of light rules, that can be violated without problem and can be cross referenced
in other concepts or constraints, which always have a severity.

### Examples

I don't want to dive deeper into the syntax of [Cypher][7], but a base examples looks
like this:

#### **test.cypher:**
```cypher
match
    (t:Type)-[:DEPENDS_ON]->(t2:Type)
return
    t, t2
```

This asks the database for any type named *t*, that depends on another type named *t2*.

## Conclusion

My showcase can be found here:

<https://github.com/unexist/showcase-architecture-testing-quarkus>

[1]: https://www.archunit.org/
[2]: https://jqassistant.org/
[3]: https://structure101.com/
[4]: https://www.hello2morrow.com/products/sotograph
[5]: https://neo4j.com/
[6]: https://neo4j.com/developer/neo4j-browser/
[7]: https://neo4j.com/developer/cypher/
