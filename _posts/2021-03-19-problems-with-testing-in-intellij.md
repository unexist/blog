---
layout: post
title: Problems with testing in IntelliJ
date: 2021-03-19 08:40 +0100
author: Christoph Kappel
tags: tools intellij
categories: tech
---
Importing projects in [IntelliJ][1] is usually a problem. I haven't figured out, why I always end up
with projects, that can be build with maven without any problems and [IntelliJ][1] fails to find
and index the dependencies.

FWIW: I'd expect that the pom is readable for the bundled maven as well.

## JUnit5

Sometimes the import fails even more spectacular and the test runner fails with goodies like this:

#### **random.log:**
```log
Exception in thread "main" java.lang.NoClassDefFoundError: org/junit/platform/engine/TestDescriptor
```

It took me quite some time to figure this out. The problem here is intellij failed to properly
create the modules and assigned paths randomly among them.

That means the classpaths are wrong and the error message makes actually sense.

So when this error happens, open the **Module settings** inside of [Intellij][1] and switch to the
**modules** tab. Verify that there is only one module or rather modules that match the structure
of your project.

_NOTE: [IntelliJ][1] usually tells you, when the settings are bogus when you try to quit the dialog
via **OK**.:_

Things you should look for:

* Same **source**, **test source**, **ressource** path cannot be split/re-used in different modules
* Each of the above should exist

[1]: https://www.jetbrains.com/idea/
