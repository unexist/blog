---
layout: post
title: Service virtualization
date: %%%DATE%%%
author: Christoph Kappel
tags: tech hoverfly testcontainers podman showcase
categories: testing showcase
toc: true
---
If you've ever written a test for software, that wasn't designed to be tested, you probably know
the problem of mixed up business logic through-out the layers.
And it gets even worse, when your use case isn't isolated into a single service and relies on some
external communication with other ones.

Containerization e.g. via [Podman][] eases the pain and allows to run instances of all required
services along with our service in a complex integration test.
Alas, this solution doesn't scale well, especially when the required services have further
requirements themselves and you basically have to start up a whole landscape or are really
difficult to set up.

In this post I want to demonstrate another option namely **service virtualization**, which allows
to consider these kind of requirements as a blackbox and (to further stretch this metaphor) to
record and playback requests.

Sounds interesting? Let me introduce you to [Hoverfly][].

## Hoverfly

Simply speaking, [Hoverfly][] acts like a transparent proxy and can be easily hooked up into the
[JVM][] via the [JUnit5][] extension lifecycle.
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

**<1>** Start [Hoverfly][] in simulation mode. \
**<2>** Use the [DSL][] to configure the reply. \
**<3>** Return a new [UUID][] on a request to `/id`. \
**<4>** Stupidly check the status code.

### Integration in Quarkus

The general test setup in [Quarkus][] is a bit different and can be greatly eased by using a test
lifecycle manager.
(If you are interested into the why, please see [this][] issues on [GitHub][].)

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

**<1>** Configure [Hoverfly][] to run in simulation mode. \
**<2>** Also define a [UUID][] for a reply. \
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

<https://github.com/unexist/showcase-integration-testing-quarkus>

```
https://hoverfly.io/
https://docs.hoverfly.io/projects/hoverfly-java/en/latest/pages/junit5/junit5.htm
https://github.com/quarkusio/quarkus/issues/9884
```