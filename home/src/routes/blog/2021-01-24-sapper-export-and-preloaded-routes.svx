---
layout: post
title: Sapper export and preloaded routes
date: 2021-01-24T13:45:00-08:00
category: engineering
tags:
  - web-development
  - svelte
---

Sapper is a [server-side
rendering](https://en.wikipedia.org/wiki/Server-side_scripting) framework that
is effectively a port of [Next.js](https://nextjs.org/) in Svelte. I am using it
to generate static websites with routing capabilities. During `sapper export --legacy`, sapper will go through all reachable routes and execute any preloaded
content before creating a static bundle for each route.

In the `routes/git-logs.txt.js`, I can write a small function that is called on
the route which is served up by the server.

```javascript
import child_process from "child_process";

export function get(req, res, next) {
  let logs = child_process.execSync(
    `git log -n 10 --pretty="format:%hn %cd %s" --date=rfc`
  );
  res.end(logs);
}
```

This fetches the last 10 commits from the local git repository and serves it as
a text file at the route `git-logs.txt`. Then inside of `routes/index.svelte`, I
can write code to access this route.

```javascript
<script context="module">
  export async function preload() {
    let resp = await this.fetch("git-logs.txt");
    return { logs: await resp.text() };
  }
</script>

<script>
  export let logs;
</script>
```

This is great when I want to include pieces of data from the system or an
external source at build time e.g. a version from `package.json`. It's important
to note that running fetch outside of `preload` in the module script will not be
loaded by `sapper export`. It will work fine in development or when running on a
server, so take the time to understand the different options.
