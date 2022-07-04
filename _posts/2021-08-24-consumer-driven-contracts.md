---
layout: post
title: Consumer-driven contracts
date: 2021-08-24 12:14 +0200
last_updated: 2021-08-24 12:14 +0200
author: Christoph Kappel
tags: tools testing consumer-driven-contracts pact showcase
categories: testing showcase
toc: true
---
We all know the problems, when two (not opposing) teams (A and B) work on specific services and the
expectation here is, that after a successful deployment both services work together happily every
after.

So the first deployment is done and everything is working fine. The next milestone has to be
reached and one team wants to add a new shiny feature, which unfortunately breaks the public API and
violates the contract between both services?

For the ease of the discussion, let us say team A is responsible for the **consumer** of the public
API and team B takes care of the **producer**.

![image](/assets/images/consumer_driven_contracts/pact_normal_flow.png)

This scenario has lots of problems, but let us talk about two in detail:

1. The **consumer** cannot verify its assumptions about the public facing API independently.
2. The **producer** cannot easily verify, if any change of the API breaks any existing contract.

## Mocking

This whole problem isn't new and we have a perfect hammer for this particular nail: We just create
a **mock** or even better a **fake** from the **producer** and test the **consumer** against it:

![image](/assets/images/consumer_driven_contracts/pact_mock_flow.png)

..but how does this help to validate assumptions? Or even worse: Who is responsible for updating the
mock or fake, when the API really changes?

There has to be another way..

## Consumer-driven Contracts

Consumer-driven Contracts (CDC) is a way to help both teams with their problems: It allows the
**consumer** to state, what it expects from a **producer** in a well-defined format. This format
(or **contract**) includes all the interaction of the two services with the results.

In other words:

> A contract between a consuming service and a providing service, stating what the consumer wants
from a providing service, in a defined format.
<cite>Ian Robinson, <https://martinfowler.com/articles/consumerDrivenContracts.html></cite>

Alas, consumer-driven contracts are **not** a [silver bullet][1]:

- They cannot test business logic.
- They still succeed, when something underlying changes, but the format stays the same.
- They are **not** a Service Level Agreement (SLA).
- They cannot validate external API responses.

That out of the way, let us focus on a examples.

There are some frameworks available to support this, like [Spring Cloud Contract][2] and
[Pact][3] - we will focus on the latter one and see shortly, what it really can do for us.

## Pact

[Pact][3] provides a complete set of [supporting tools for maven][4] and a [broker][5], to ease the
collaboration and sharing of contracts and the results.

### Features

#### JSON DSL

[Pact][3] comes with a JSON DSL, which allows to easily describe the resulting JSON. A complete
explanation of the markup can be found at the [pact.io website][6], but here is a short
example from the [showcase][7]:

###### **TodoResourcePactConsumer.java**:
```java
@ExtendWith(PactConsumerTestExt.class)
@Pact(consumer = "Todo-Consumer")
public RequestResponsePact createPact(PactDslWithProvider builder) {
    return builder // <1>
            .given("a running server")
            .uponReceiving("POST /todo")
            .path("/todo")
            .method("POST")
            .body(new PactDslJsonBody()
                .stringValue("title", "string")
                .stringValue("description", "string")
                .booleanType("done", true)
                .object("dueDate")
                    .stringValue("due", "2021-05-07")
                    .stringValue("start", "2021-05-07")
            )
            .willRespondWith()
            .status(201)
            .toPact();
}
```

**<1>** The builder from the [DSL][6] is used to build the request and describe the expected result.

#### JUnit5 integration

[Pact][3] comes with a proper [JUnit5 integration][8], so specifying the actual expected results
can be done pretty easy with the corresponding extension:

###### **TodoResourcePactConsumer.java**:
```java
@Test
void todoCheckPactTest(MockServer mockServer) throws IOException {
    ObjectMapper mapper = new ObjectMapper();
    String endpoint = mockServer.getUrl() + "/todo";

    HttpResponse response = Request.Post(endpoint)
            .bodyString(mapper.writeValueAsString(createTodo()), ContentType.APPLICATION_JSON)
            .execute().returnResponse();

    assertThat(response.getStatusLine().getStatusCode()).isEqualTo(201); // <2>
}
```

**<2>** And the actual verification takes place here.

#### Broker

The [broker][6] allows to uncouple **consumer** and **producer**, so that instead of talking
directly to each other during tests the communication looks like this:

![image](/assets/images/consumer_driven_contracts/pact_broker_flow.png)

This makes it possible for both sides to work independently on their services without interrupting
other teams.

### Test flow

#### Define the expected result on consumer side

During the test execution, [Pact][3] creates a mock server with provider stubs in place. Then, the
requests are sent and the results are compared with the actual definition.

Once this succeeds, a contract file is created and stored in **targets/pacts**.

So to sum this up, the actual contracts are defined as code, can therefore be reproduced and are
easy to understand for developers.

#### Share the generated contract

Sharing the generated contract is also pretty easy:

The example of the [showcase][7] is configured to use a [Pact][2] broker running inside of a
[docker][9] container and can be reached under **http://localhost:9292**, once it has been started
via `make docker`.

And with a call of `mvn pact:publish` or `make pact-publish` the contract should be visible in the
broker:

![image](/assets/images/consumer_driven_contracts/pact_broker_publish.png)

#### Test the provider

Moving to the provider side, it is time to verify the contract against the actual implementation now.

###### **TodoResourcePactProvider.java**:
```java
@Provider("Todo-Provider")
@PactBroker(valueResolver = AbstractPactTest.PactValueResolver.class)
public class TodoResourcePactProvider extends AbstractPactTest {
    @TestTemplate
    @ExtendWith(PactVerificationInvocationContextProvider.class)
    void pactVerificationTestTemplate(PactVerificationContext context) {
        context.verifyInteraction();
    }

    @BeforeEach
    void before(PactVerificationContext context) {
        context.setTarget(new HttpTestTarget("localhost", 8081, "/")); // <1>
    }

    @BeforeAll
    static void setUp() {
        startApplication(); // <2>
    }

    @State("a running server") // <3>
    public void runningState() {
        /* All preparations done? */
    }
}
```

**<1>** In this first step the test target is set to the testing configuration of quarkus. \
**<2>** Before the first test run, the Quarkus application has to be started manually \
**<3>** This defines a state, which can be used for different setups.

There are multiple ways to start this verification step, the most convenient way is to just execute
`mvn test` and then let [Pact][3] upload the result to the broker.

Another option is to execute the aptly named `mvn pact:verify` or `docker pact-verify`.

When the test runs successfully, the output should look like this:

###### **Log**:
```log
Verifying a pact between Todo-Consumer (0.1) and Todo-Provider

  Notices:
    1) The pact at http://localhost:9292/pacts/provider/Todo-Provider/consumer/Todo-Consumer/pact-version/dd4742201f8511b7f05c31f5038c319b2deec46d is being verified because it matches the following configured selection criterion: latest pact between a consumer and Todo-Provider

  [from Pact Broker http://localhost:9292/pacts/provider/Todo-Provider/consumer/Todo-Consumer/pact-version/dd4742201f8511b7f05c31f5038c319b2deec46d/metadata/c1tdW2xdPXRydWUmc1tdW2N2bl09MC4x]
  Given a running server
         WARNING: State Change ignored as there is no stateChange URL
  POST /todo
    returns a response which
      has status code 201 (OK)
      has a matching body (OK)
```

And the verification result should also be visible in an updated listing:

![image](/assets/images/consumer_driven_contracts/pact_broker_verify.png)

### Problems

#### Connection to invalid SSL certificates

The maven part of [Pact][3] runs inside of another JVM, so adding flags to maven to bypass any SSL
issues like `-Dmaven.wagon.http.ssl.insecure=true` doesn't help here.

We ultimately got rid of this problem by adding the certificate to the matching JVM:

###### **Console**:
```shell
curl https://some.host/RootCA.crt -o RootCA.crt
keytool -import -alias RootCA -cacerts -file RootCA.crt -storepass changeit -noprompt
```

A colleague of mine also opened a feature request and gladly they accepted and added it:

<https://github.com/pact-foundation/pact-jvm/issues/1413>

## Conclusion

[Pact][3] takes good care of the bulk work of the consumer-driven contract flow, so it is quite easy
go get started with it. In general, adding this to CICD can still be a challenge, especially if
many stages test or dev may contain different versions of the services.

My showcase can be found here:

<https://github.com/unexist/showcase-cdc-quarkus>

[1]: https://en.wikipedia.org/wiki/No_Silver_Bullet
[2]: https://spring.io/projects/spring-cloud-contract
[3]: https://pact.io/
[4]: https://docs.pact.io/implementation_guides/jvm/provider/maven/
[5]: https://docs.pact.io/getting_started/sharing_pacts/
[6]: https://docs.pact.io/implementation_guides/jvm/consumer/#building-json-bodies-with-pactdsljsonbody-dsl[
[7]: https://github.com/unexist/showcase-testing-quarkus
[8]: https://docs.pact.io/implementation_guides/jvm/provider/junit5/
[9]: https://www.docker.com/