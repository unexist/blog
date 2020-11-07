---
layout: post
title:  "Lessons learned"
date:   2020-10-07 12:00:00 +0200
author: Christoph Kappel
tags:   tools testing ruby watir chromedriver headless
---
A friend of mine approached me with a request to - let us say automate -
a web request to a not-to-be-named raffle. I looked into it and was
instantly hooked. Both price and challenge are interesting.

I wrote quite a few scraper in my time, so after a few lines good ol'
Ruby, with the help of [mechanize](https://github.com/sparklemotion/mechanize),
the first shot was ready and failed miserably due to *CSRF*.

After a quick check, yes they really use a pesudo-random token, which is injected
into the DOM and a hidden input field via JS.

I had two options now:

1. Understand the code that writes the CSRF into the dom
2. Find a scraper with a JS engine

In my day job, we always like to play with with e2e-testing, which mostly
involves scripts, that remote-control a web browser. 

That said, I had a few glances at this stack again. And after some more reading,
I settled on [watir](http://watir.com/) and [chromedriver](https://chromedriver.chromium.org/).

### Watir

The API of [watir](http://watir.com) is really amazing and easy to use:

```ruby
require "watir"

browser = Watir::Browser::new

browser.goto "https://blog.unexist.dev"

browser.close
```

I think the example is pretty self-explanatory, it opens up a remote session and
points the browser to the given url. When you start that in e.g. irb, you can
REPL your way to the desired outcome.

```ruby
browser.link(visible_text: /GitHub/).when_present.click
```
The above example looks for a link with *GitHub* in its visible text and click
it, when present. Easy as that.

### Headless?

One problem solved, this runs nicely on my *local* machine. Now it would be best,
if I can just deploy it on a server without installing the whole docker stack. 

Since we are targeting Linux, headless support is kind of built-in. And after a
quick search I found [headless](https://github.com/leonid-shevtsov/headless).

This *gem* wraps the handling of a virtual framebuffer for you and, as it turns 
out, works pretty well with my stack:

```ruby
require "watir"
require "headless"

Headless.ly do
    browser = Watir::Browser::new

    browser.goto "https://blog.unexist.dev"

    browser.close
end
```
