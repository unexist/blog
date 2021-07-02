---
layout: post
title: Property based testing
date: 2020-08-13 12:10:00 +0200
author: Christoph Kappel
tags: java testing showcase
categories: software-design
---
I initially read about the Python framework [Hypothesis][1] and I must say I like the overall idea
to just define ranges and the framework does dozen of tests with semi-random values.

This might lead to combinations, you normally wouldn't think of.

So since there is a java version ([jqwik][2]) of it, let us look into the various generators
that can be used.

## First steps

In general, the whole handling of pretty straight forward.

#### **TodoTest.java**:
```java
@PropertyDefaults(tries = 10) // <1>
public class TodoTest {

    @Property
    public void testCreateTodo(@ForAll String anyStr) { // <2>
        Todo todo = new Todo();

        todo.setTitle(anyStr); // <3>
        todo.setDescription(anyStr);

        assertThat(todo.getTitle()).isNotNull(); // <4>
        assertThat(todo.getDescription()).isNotNull();
    }
}
```

**<1>**: This tells [jqwik][2] how often to run the test with different generator values. \
**<2>**: Here `@ForAll` just marks the value that is taken from a generator. \
**<3>**: The parameter `anyStr` can now be used like you'd expect.

## Adding a bit of complexity

#### **TodoTest.java**:
```java
@PropertyDefaults(tries = 10)
public class TodoTest {
    private static final int FUTURE_TIME = 1741598467;

    @Property
    public void testCreateTodoWithDate(@ForAll String anyStr,
                                       @ForAll @IntRange(min = TodoTest.FUTURE_TIME) int unixtime) // <1>
    {
        Todo todo = new Todo();

        todo.setTitle(anyStr);
        todo.setDescription(anyStr);

        DueDate dueDate = new DueDate();

        dueDate.setStart(LocalDate.now());
        dueDate.setDue(Instant.ofEpochMilli(unixtime * 1000L) // <2>
                .atZone(ZoneId.systemDefault()).toLocalDate());

        todo.setDueDate(dueDate);

        /* Arbitrary and contrived test <3> */
        Condition<Todo> cond1 = new Condition<>(t ->
                t.getDueDate().getStart().isBefore(t.getDueDate().getDue()),
                "Start date is before due date");
        Condition<Todo> cond2 = new Condition<>(TodoBase::getDone,
                "Todo must not be done");

        assertThat(todo).is(allOf(cond1, cond2));
    }
}
```

**<1>**: This is pretty much the same, besides it includes an `@IntRange` now. \
**<2>**: Here we use `unixtime` as an input to create dates. \
**<3>**: A small test of test combinators..

## Conclusions

During my tests I've found some interesting bug, mostly related to empty string and some weird
combination of unicode characters. I think the handling is pretty easy and generators can be a huge
help to avoid some kind of errors.

As usual, my showcase can be found here:

<https://github.com/unexist/showcase-testing-quarkus>

[1]: https://hypothesis.readthedocs.io/en/latest/
[2]: https://jqwik.net/