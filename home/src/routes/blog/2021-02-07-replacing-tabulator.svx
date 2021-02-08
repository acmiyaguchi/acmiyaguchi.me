---
layout: post
title: Replacing tabulator with a minimal table component
date: 2021-02-07T17:08:00-08:00
category: Engineering
tags:
  - web development
  - svelte
---

<script>
import Table from "../../components/Table.svelte"

// https://stackoverflow.com/a/8084248
let data = [...Array(128).keys()].map(key => ({
    index: key,
    value: Math.random().toString(36).substring(7).repeat(8)
}))

let paginationSize = 8;

</script>

<style>
  img {
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
  }
</style>

[Tabulator](http://tabulator.info/) is a piece of software that I've used across
several projects. I've used it on my website, but my design sensibilities tell
me to be lean with my dependencies on the site. I don't need all of the fancy
features that the library provides, like the virtual dom and styling. I replaced
the table with a component that has fewer dependencies. Play around with it by
manipulating the pagination size below.

<label>
	<input type=number bind:value={paginationSize} min=4 max=16>
	<input type=range bind:value={paginationSize} min=4 max=16>
</label>

<Table data={data} {paginationSize} />

I suggest taking a look at the [analytics](analytics) page too. You'll see
similar tables in action: ![analytics page](assets/2021-02-07/analytics.png)

The [full source code can be found in the site repository][github].

[github]: https://github.com/acmiyaguchi/acmiyaguchi.me/blob/3d80a5280f7293d0c2a055d4a3c4384dbda05f41/home/src/components/Table.svelte

I've documented the table sizes here.

**Tabulator-based**

```bash
> git log -n1 --pretty=oneline
a521650e470e04fabb04bc0fd78a7cc29d334824 Move plot into components
> npm build
> ls .\__sapper__\build\client\Table*
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----          2/7/2021   1:40 PM          22632 Table-3a3654c8.css
-a----          2/7/2021   1:40 PM         359791 Table.e1dfc581.js
```

**Svelte-based**

```bash
> git log -n1 --pretty=oneline
834bd147596bd4ae197f22c1f5cde793f6b408db (HEAD -> main, origin/main) Remove tabulator
> npm build
> ls .\__sapper__\build\client\Table*
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----          2/7/2021   1:35 PM             81 Table-8db1bf94.css
-a----          2/7/2021   1:35 PM          75367 Table.6a05f367.js
```

The original one based on Tabulator is 360kb of code and 23kb of CSS, while the
new one is 75kb of code with 0.08kb of CSS. I like the leaner code, and having a
Svelte component leaves a lot of flexibility for future functionality.
