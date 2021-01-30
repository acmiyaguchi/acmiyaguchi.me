---
layout: post
title: Troubles with Protosaur and Svelte
date: 2021-01-22T22:24:00-08:00
category: engineering
tags:
  - web-development
  - svelte
---

At Mozilla, we have a micro-service called
[protosaur.dev](https://protosaur.dev/) that hosts static websites from Google
Cloud Storage buckets. It proxies requests to cloud storage
buckets and serves content behind our authentication system. It reduces the
overhead of deploying prototypes of data applications. I've deployed this
[schema deploy dashboard for
mozilla-pipeline-schemas](https://protosaur.dev/mps-deploys/), which regulary
scrapes BigQuery to determine timestamps of updates.

I've been writing web applications using [Svelte](https://svelte.dev/) recently.
It's been a boon to my productivity -- I can go from idea to materialized
concepts within a few hours or days. It's my favorite tool of 2020 (probably
going into this year). The one problem with single page applications is that
they do not play well when hosted in a directory in a domain.

I ran into this as I was rewriting an [ETL query log
tool](https://github.com/mozilla/etl-graph) called etl-graph. It was deployed to
`protosaur.dev/etl-graph`, which worked out well when it was just a single page.
However, I started adding routing to the page. There is an exploration,
statistics, and artifact page which all have their own sub-routes. With the
route into the domain, it is difficult to fetch assets relative to the
application root. For example, consider the following fetch:

```javascript
let resp = fetch("data/edgelist.json");
```

Instead of fetching from `protosaur.dev/etl-graph/data/edgelist.json`, the
browser looks from the root of the domain i.e.
`protosaur.dev/data/edgelist.json`. This breaks the application and requires a
work-around. One way is to encode the application path into a pattern and
replace it before running it:

```javascript
let resp = fetch("__root__/data/edgelist.json");
```

`__root__` can be the empty when developing locally. When building n production,
`__root__` can be `etl-graph`. This solution is hacky at best. The alternative
is to provision a sub-domain where the application has control over the routes.
This is the solution that sites like [glitch.me](https://glitch.me) and
[netlify.dev](https://netlify.dev) adopt, and this too is how protosaur.dev
solves it.
