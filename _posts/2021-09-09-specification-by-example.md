---
layout: post
title: Specification by example
date: 2021-09-09 14:17 +0200
author: Christoph Kappel
tags: tools testing specification-by-example showcase
categories: testing showcase
toc: true
---
Testing is one of the few topics developers like to avoid when possible and admittedly I am no
exception here. During my career I either thought tests should be written by testing engineers or
there is no sense in testing something at all. Maybe, one of the problems is that you are too close
to the frontier and need to step back to see the actual benefit?

To get a broader view and understanding, I started reading about different testing ideas, strategies
and methodologies. During that I learned quite a lot, like  [Test-driven Development][1] can be
really helpful and rewarding, but maybe this is something I can lay out in another post. Here I
want to write about something that I also found interesting, namely [Acceptance Testing][2].

## Acceptance Testing

So what do we have here? After reading the second linked [Wikipedia][3] article you should be pretty
much covered, but let me still explain it in layman's terms:

Acceptance tests are tests, that help to ~~prove~~ verify, that a story or more in general some
feature is ready for production and this unit of work is done. So far, so good.

Now the tricky question: **When are these tests defined and by whom actually?**

Both **when** and **by whom** are interesting, since it is a bit different than my past self would
have expected. I wrote above, that I expected test engineers to write all kind of tests and this
isn't so far from the truth. Another expectation was, that these test engineers either write tests
in parallel, while the developer writes the code or afterwards, once development is done.

## Knowledge Sharing

This flow has some inherent problems about knowledge sharing: Developers can only catch problems
they are aware of, [Rumsfeld][4] got the gist of it nicely with his phrase about
[unknown unknowns][5]. And testers have their own share of knowledge about this specific type of
product or even better some testing heuristics. (There is a nice
[test heuristics cheat sheet][6] though.)

Like so often in our business, communication is key and some of the problems can be easily avoided,
when developer and tester start talking to each other before any actual work is done.

## Three Amigos

[Three Amigos][7] or **Specification Workshop** is a way to get this started: When a new story has
to be written, the story's stakeholder, a developer who will most likely be tasked with it and a
tester have a short session about what has to be done. During this session, they share their
knowledge, talk about edge cases and define test cases how this story can be verified and accepted.

The format of the output is completey open, ranging from simple lines written down on the story
card or a rough table with values of edge cases, that have to be considered. The key here is the
exchange of knowledge, which directly improves the understanding of the story of the participants
and also might lead to interesting questions and problems.

Let us talk about some of the existing tools to support this now.

## Cucumber

If you fire up Google and search for `tool for automated acceptance testing`, one of the first few
matches is probably [Cucumber][8], obviously depending on your personal filter bubble. It uses the
[given-when-then][9] format (originally invented by [Dan North][10]) to write structured test
cases and to evolve a [domain-specific language][11]) for use cases in a language called
[Gherkin][12].

The resemblance between [given-when-then][9] and the format coined by [Connextra][13] is no
accident: The idea here is to directly be able to translate one to the other.

Getting started with [Gherkin][12] is pretty easy and self-explanatory. I don't want to go much in
gory [detail][14], so it probably suffices to say there is the set of three commands and some
conjunctions to formulate the use case, similar to the english language (or some other; there is
support for a few) and example values can be loaded from tables:

###### **todo.feature**:
```gherkin
Feature: Create a todo
  I want to create a new todo

  Scenario Outline: Dream of a todo
    Given I imagine a todo "<title>"
    And a description of "<description>"
    And starting on "<start>"
    And lasting no longer than "<due>"
    And still not "<done>"
    When I would ask for the status code
    Then I should be told "<status>"

    Examples:
      | title | description | start      | due        | done  | status |
      | Test  | Test        | 2021-01-01 | 2021-02-01 | false | 201    |
      |       | Test        | 2021-01-01 | 2021-02-01 | false | 201    |
      | Test  |             | 2021-01-01 | 2021-02-01 | false | 201    |
      | Test  | Test        |            | 2021-02-01 | false | 201    |
      | Test  | Test        | 2021-01-01 |            | false | 201    |
      | Test  | Test        | 2021-01-01 | 2021-02-01 |       | 201    |
      |       |             |            |            |       | 400    |
```

As you can see, the format of **features** is pretty open and the only limit is probably the
creativity of the writer. With this at hands it is easy to invent some kind of language for the
business cases and doesn't matter if it's targeted to finance, logistics or insurance.

Once the feature is ready, someone needs to write the test fixture or **steps** in the lingo of
[Cucumber][8]. Here is a small excerpt from my [showcase][15]:

###### **TodoSteps.java**:
```java
public class TodoSteps {
    @Given("I imagine a todo {string}")
    public void given_set_title(String title) {
        this.todoBase.setTitle(title);
    }

    @And("a description of {string}")
    public void given_set_description(String description) {
        this.todoBase.setDescription(description);
    }
}
```

The [Java bindings][16] provide us with lots of convenient annotations to handle the string matching
and we can assemble the test piecemeal.

So let us check the output of the [Cucumber][8] test runner:

###### **Log**:
```gherkin
Scenario Outline: Dream of a todo         # src/test/resources/features/todo.feature:15
  Given I imagine a todo "Test"           # dev.unexist.showcase.todo.domain.todo.TodoSteps.given_set_title(java.lang.String)
  And a description of "Test"             # dev.unexist.showcase.todo.domain.todo.TodoSteps.given_set_description(java.lang.String)
  And starting on "2021-01-01"            # dev.unexist.showcase.todo.domain.todo.TodoSteps.given_set_start_date(java.lang.String)
  And lasting no longer than "2021-02-01" # dev.unexist.showcase.todo.domain.todo.TodoSteps.given_set_due_date(java.lang.String)
  And still not "false"                   # dev.unexist.showcase.todo.domain.todo.TodoSteps.given_set_done(java.lang.String)
  When I would ask for the status code    # dev.unexist.showcase.todo.domain.todo.TodoSteps.when_get_status()
  Then I should be told "201"             # dev.unexist.showcase.todo.domain.todo.TodoSteps.then_get_status_code(java.lang.String)
```

So let us take a step back and talk about what we have archived so far:

1. We've created some kind of language with a modest chance, that it is understandable by other
than technical folks, although they will probably never check out the source code to read it and
have to rely on reports.

2. We can split the task of writing the fixture and the steps, but introduce problems how to combine
them again and how to make the results visible.

3. Another issue here is that we've introduced tables to test what in particular? Based on the
description of the values and the columns, is clear to everyone what kind of use case this feature
really addresses?

Let us check how [FitNesse][17] tries to solve these problems.

### FitNesse

[Fitnesse][17] is another testing framework, which also uses the table approach, but provides
access to the test cases, definitions and results in a unique way: It comes bundled with a
standalone [wiki engine][18] and can be accessed with any browser:

![image](/assets/images/20210909-fitnesse_wiki_browser.png)

Before you ask, yes you can also run it headless in case you want to integrate it into a CI
pipeline. *We all know that you want to do that, right?*

```shell
$ java -jar lib/fitnesse.jar -c "FrontPage?suite&suiteFilter=MustBeGreen&format=text"
```

The wiki itself consists of different [types of pages][19]:
- **Static**, normal pages like the ones you know from [Wikipedia][3].
- **Suites**, collections of different test pages, which can be executed.
- **Tests**, actual test cases, which also can be executed.

Depending on the testing engine, a **suite** requires some additional setup. In my examples I've
used the [SLiM][20] engine and this looks like this:

###### **Wiki: Suite TodoSlim**:
```asc
!1 Test Suite for Slim based REST calls

This suite just consists of a single test of the endpoint.

----
!contents -R2 -g -p -f -h

!*< SLiM relevant stuff

!define TEST_SYSTEM {slim}

!path /Users/unexist/Projects/showcase-testing-quarkus/todo-service-fitnesse/target/classes/
!path /Users/unexist/Projects/showcase-testing-quarkus/todo-service-fitnesse/target/test-classes/
!path ${java.class.path}
*!
```

The markup is a bit different than you are probably used to, so here is quick heads up: Commands
usually start with an exclamation point (like `!path`) and the output of anything enclosed in
asterisks is silently consumed.

Let us talk about an actual test page:

###### **Wiki: Test SlimTest**:
```asc
!1 Test status code of the REST endpoint

This test runs different calls to the REST endpoint

----
!contents -R2 -g -p -f -h

|import|
|dev.unexist.showcase.todo.domain.todo|

!|Todo Fixture                                                      |
| title   | description | start date | due date   | done  | status? |
| Test    | Test        | 2021-01-01 | 2021-02-01 | false | 201     |
|         | Test        | 2021-01-01 | 2021-02-01 | false | 201     |
| Test    |             | 2021-01-01 | 2021-02-01 | false | 201     |
| Test    | Test        |            | 2021-02-01 | false | 201     |
| Test    | Test        | 2021-01-01 |            | false | 201     |
| Test    | Test        | 2021-01-01 | 2021-02-01 |       | 201     |
|         |             |            |            |       | 400     |
```

The interesting points here are the two tables: The first one specifies the path to the fixture that
should be imported for this test and the second one the actual values. Although a bad example, I
used the same table structure from the [Cucumber][8] example just to make my point later in this
blog post.

And here is another excerpt from the fixture:

###### **TodoFitnesseFixture.java**:
```java
public class TodoFitnesseFixture {
    private TodoBase todoBase;
    private RequestSpecification requestSpec;

    public void setDone(Boolean isDone) {
        this.todoBase.setDone(isDone);
    }

    public int status() {
        Response response = given(requestSpec)
                .when()
                .body(this.todoBase)
                .post("/todo");

        return response.getStatusCode();
    }
}
```

[FitNesse][17] automatically uses the column names of the table as the accessos of the fixtures,
so the column `done` directly relates to the setter `setDone` and `status?` to the getter `status`.
*I am not entirely sure why, but at least we got rid of half of the bean spec.*

Back to your browser: When you click on the test button at the top, [FitNesse][17] fires up and
runs the tests on the selected page - or the entire suite and updates the colors according to the
results:

![image](/assets/images/20210909-fitnesse_wiki_after.png)

Let us consonder the problems that I've mentioned before:

1. [FitNesse][17] solves the problem how non-tech-savy folk can write and run tests and also allows
a quick verification just with the use of a browser, when properly set up.

2. It kind of lacks the benefits of the [DSL][11], but from my experience it all boils down to lots
of tables anyway. ([FitNesse][17] is extendable and there are some outdated projects like
[fitnesse-cucumber-testing-system][21] which I am trying to fix [here][22] though)

3. There is still the same problem with the test cases.

Let us talk about number three.

### Concordion

[Concordion][23] is the latest addition in my [showcase][15] and also in the overall list of
frameworks that I gave a try. It is a bit similar to the idea of [Cucumber][8], with the exception
that instead of [Gherkin][14] it [instruments markdown][24] to bring flexibility to the
specification itself.

This is easier shown than it is to explain:

###### **TodoConcordion.md**:
```markdown
# Create a todo

This is an example specification, that demonstrates how to facilitate markdown
and [Concordion](https://concordion.org) fixtures.

### [Simple example](- "simple_example")

A todo is [created](- "#result = create(#title, #description)") with the simple
title **[test](- "#title")** and the matching description
**[test](- "#description")** and [saved](- "#result = save(#result)") as ID
[1](- "?=#result.getId").
```

Besides the usual [markdown][25] formatting, the interesting parts are the links:
- If you attach something like `#title` to a word, [Concordion][23] puts the word into the named
variable `title`.
- If you use an equal sign like `#result = #title`, you create an assignment.
- If you write something like `create` you call a function of the underlying
fixture.
- If you start with a question mark like `?=#result` you make an assertion of equality.

In the above example we create a Todo from a title and a description, this is a pretty easy
case and visible in the following excerpt from my [showcase][15]

###### **TodoConcordionFixture.java**:
```java
@RunWith(ConcordionRunner.class)
public class TodoConcordionFixture {
    public TodoBase create(final String title, final String description) {
        TodoBase base = new Todo();

        base.setTitle(title);
        base.setDescription(description);

        return base;
    }
}
```

When the test runner runs this test it creates following report:

![image](/assets/images/20210909-concordion_simple_test.png)

Since adding all the link instrumentation directly into the text makes its source kind of difficult
to read and follow, therefore there is a slighty extended way of creating them:

###### **TodoConcordion.md**:
```markdown
### [Simple example with different notation](- "simple_example_modified")

A todo is [created][createdCmd] with the simple title **[test](- "#title")** and
the matching description **[test](- "#description")** and [saved][savedCmd]
as ID [1](- "?=#result.getId").

[createdCmd]: - "#result = create(#title, #description)"
[savedCmd]: - "#result = save(#result)"
```

This example utilizes another way of defining links inside of [markdown][25], which is quite handy
for me because I usually do it that way in my blog as well. Once the runner writes the report it
can be opened in your browser:

![image](/assets/images/20210909-concordion_simple_test_modified.png)

All the other examples use a table, so here is a small example with a table as well:

###### **TodoConcordion.md**:
```markdown
### [Extended table example](- "extended_table")

This example combines ideas from the others ones:

| [createWithDate][][Start date][start] | [Due date][due] | [Is done?][done] |
| ------------------------------------ | ----------------| -----------------|
| 2021-09-10                           | 2022-09-10      | yes              |
| 2021-09-10                           | 2021-09-09      | no               |

[createWithDate]: - "#result = createWithDate(#start,#due)"
[start]: - "#start"
[due]: - "#due"
[done]: - "?=isDone(#result)"
```

To ease the writing of the tests, we just have to instrument the names of the columns, but it is
quite possible to do this in every row. The initial `createWithDate` is a special case and runs
before each row. If we task our test runner again to get the report we end up with this:

![image](/assets/images/20210909-concordion_table_test.png)

Time for talk about the usual points:

1. The generation of the reports is a nice addition to make it easier to read the results of a test
and the possibilities of [markdown][15] even allow the linking of different files.

2. The approach of [Concordion][23] is a bit different, instead of relying on a [DSL][11] like
[Cucumber][8] or on tables only like [FitNesse][17], it allows to easily use natural language and
enhances it. This moves some of the complexity of the specification to the writer and probably
limits who can do that at all.

3. Did you notice the difference of the tables? In the last example I just limited the values to
the ones that are actually relevant to the test case, so that the intention of the test is clearer
to the reader. This is, of course, possible with all of the named frameworks.

Conclusion time!

## Conclusion

The idea of specifications is to have some kind of living document, that can be used to transport
the intent of a feature and also show noteworthy edge cases of the implementation. They will outlast
tickets and should be the first address to go to, to understand how something works.

All three frameworks have some pros like focus on ease of writing or how to bring a specification
closer to a non-techy audience and cons like putting complexity to multiple places.

For whatever framework you choose, the real gain lies in communication: You are making a huge step
forward, if you sit together, talk about story cards and actually share your knowledge and come
to a shared understanding.

*I am personally totally intrigued by [Concordion][23], but like [FitNesse][17] I've never seen it
in a real project and I better consider the trade-offs and requirements of any solution.*

My showcase can be found here:

<https://github.com/unexist/showcase-testing-quarkus>

[1]: https://en.wikipedia.org/wiki/Test-driven_development
[2]: https://en.wikipedia.org/wiki/Acceptance_testing
[3]: https://wikipedia.org
[4]: https://en.wikipedia.org/wiki/Donald_Rumsfeld
[5]: https://en.wikipedia.org/wiki/There_are_known_knowns
[6]: https://testobsessed.com/wp-content/uploads/2011/04/testheuristicscheatsheetv1.pdf
[7]: https://en.wikipedia.org/wiki/Behavior-driven_development#The_Three_Amigos
[8]: https://cucumber.io
[9]: https://en.wikipedia.org/wiki/Given-When-Then
[10]: https://dannorth.net/
[11]: https://en.wikipedia.org/wiki/Domain-specific_language
[12]: https://cucumber.io/docs/gherkin/
[13]: https://www.oreilly.com/library/view/user-experience-mapping/9781787123502/92d21fe3-a741-49ff-8200-25abf18c98d0.xhtml
[14]: https://cucumber.io/docs/gherkin/reference/
[15]: https://github.com/unexist/showcase-testing-quarkus
[16]: https://cucumber.io/docs/installation/java/
[17]: http://fitnesse.org/
[18]: https://en.wikipedia.org/wiki/Wiki_software
[19]: http://fitnesse.org/FitNesse.UserGuide.FitNesseWiki.PageProperties
[20]: http://fitnesse.org/FitNesse.UserGuide.WritingAcceptanceTests.SliM
[21]: https://github.com/fitnesse/fitnesse-cucumber-test-system
[22]: https://github.com/unexist/fitnesse-cucumber-test-system
[23]: https://concordion.org/
[24]: https://concordion.org/instrumenting/java/markdown/
[25]: https://daringfireball.net/projects/markdown/syntax