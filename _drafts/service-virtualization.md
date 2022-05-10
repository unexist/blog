---
layout: post
title: Service virtualization
date: %%%DATE%%%
author: Christoph Kappel
tags: tech hoverfly podman showcase
categories: testing showcase
toc: true
---
If you've ever written a test for software, that wasn't designed to be tested, you probably know
the problem of mixed up business logic through-out the layers.
And it gets even worse, when your use case isn't isolated into a single service and relies on some
external communication with other ones.

Containerization e.g. via [Podman][6] eases the pain and allows to run instances of all required
services along with our service in a complex integration test.
Alas, this solution doesn't scale well, especially when the required services have further
requirements themselves and you basically have to start up a whole landscape or are really
difficult to set up.

In this post I want to demonstrate another option namely **service virtualization**, which allows
to consider these kind of requirements as a blackbox and (to further stretch this metaphor) to
record and playback requests.

Sounds interesting? Let me introduce you to [Hoverfly][3].

## Hoverfly

Simply speaking, [Hoverfly][3] acts like a transparent proxy and can be easily hooked up into the
[JVM][5] via the [JUnit5][4] extension lifecycle.
From there, it can record requests, simulate them or even do both at once, when the destination
address isn't reachable.

### Simple example

This is probably easier to understand with a simple example:

```java
public class IdServiceTest {
    private static final String SERVICE_URL = "localhost:8085";

    @ClassRule
    public static HoverflyRule hoverfly = hoverfly.inSimulationMode( // <1>
        dsl( // <2>
            service(SERVICE_URL)
                .get("/id")
                .willReturn(
                    success(UUID.randomUUID().toString(), MediaType.APPLICATION_JSON)) // <3>
        )
    );

    @Test
    public void shouldGetId() {
        given()
            .spec(new RequestSpecBuilder().setBaseUri("http://" + SERVICE_URL).build())
        .when()
            .get("/id")
        .then()
            .statusCode(200); // <4>
    }
}
```

**<1>** Start [Hoverfly][3] in simulation mode. \
**<2>** Use the [DSL][1] to configure the reply. \
**<3>** Return a new [UUID][9] on a request to `/id`. \
**<4>** Stupidly check the status code.

### Integration in Quarkus

The general test setup in [Quarkus][7] is a bit different and can be greatly eased by using a test
lifecycle manager:
(If you are interested into the why, please see [this][8] issues on [GitHub][2].)

```java
public class HoverflyResource implements QuarkusTestResourceLifecycleManager {
    private static final String SERVICE_URL = "localhost:8085";

    private Hoverfly hoverfly;

    @Override
    public Map<String, String> start() {
        this.hoverfly = new Hoverfly(HoverflyConfig.localConfigs()
                .proxyLocalHost()
                .destination(SERVICE_URL)
                .proxyPort(8080), HoverflyMode.SIMULATE); // <1>

        this.hoverfly.start();
        this.hoverfly.simulate(
            dsl(
                service(SERVICE_URL)
                    .get("/id")
                    .willReturn(
                        success(UUID.randomUUID().toString(), MediaType.APPLICATION_JSON) // <2>
                    )
                )
            );

        return Map.of("id.service.url", SERVICE_URL); // <3>
    }

    @Override
    public void stop() {
        this.hoverfly.close();
    }
}
```

**<1>** Configure [Hoverfly][3] to run in simulation mode. \
**<2>** Also define a [UUID][9] for a reply. \
**<3>** Expose the service url for convenience.

```java
@QuarkusTest
@QuarkusTestResource(value = HoverflyResource.class, restrictToAnnotatedClass = true) // <4>
public class TestIdServiceHoverfly {

    @ConfigProperty(name = "id.service.url", defaultValue = "") // <5>
    String serviceUrl;

    @Test
    public void shouldGetId() {
        given()
            .spec(new RequestSpecBuilder().setBaseUri("http://" + this.serviceUrl).build())
        .when()
            .get("/id")
        .then()
            .statusCode(200); // <6>
    }
```

**<4>** Restrict this resource to annotated test classes, otherwise it is always started for other tests as well. \
**<5>** Fetch the service url from config. \
**<6>** And do our stupid test again.

## Conclusion

Both examples demonstrate, how [Hoverfly][3] can easily be used to simulate requests sent to
specific addresses and allows easier testing of tightly coupled services, without firing them up.

There is a plethora of other cool features bundled into [Hoverfly][3] which I haven't mentioned
here, like verification of messages or even to act a standalone webserver, so please check it
out for yourself.

As always, here is my showcase with some more examples:

<https://github.com/unexist/showcase-integration-testing-quarkus>

[1]: https://docs.hoverfly.io/projects/hoverfly-java/en/latest/pages/corefunctionality/dsl.html
[2]: https://github.com/
[3]: https://hoverfly.io
[4]: https://docs.hoverfly.io/projects/hoverfly-java/en/latest/pages/junit5/junit5.htm
[5]: https://en.wikipedia.org/wiki/Java_virtual_machine
[6]: https://podman.io/
[7]: https://quarkus.io/
[8]: https://github.com/quarkusio/quarkus/issues/9884
[9]: https://en.wikipedia.org/wiki/Universally_unique_identifier
