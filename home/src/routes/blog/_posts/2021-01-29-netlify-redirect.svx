---
layout: post
title: Migrating blog routes using Netlify redirects
date: 2021-01-29T23:06:00-08:00
category: Engineering
tags:
  - web development
---

I recently moved my blog posts from https://blog.acmiyaguchi.me to
https://acmiyaguchi.me/blog/ in order to integrate the content with the rest of
my website. I'm more comfortable building websites now than I was 3 years ago,
and am excited to write and build more things. One of the downsides of moving
everything to a route from the subdomain is that the old links have disappeared
from the internet all together because I shut down the [Jekyll-based
blog](https://jekyllrb.com/) and moved the blog subdomain to point to the main
website.

Netlify provides a set of [redirect and
rewrite](https://docs.netlify.com/routing/redirects/) rules that are powerful
for managing routes and solving this particular problem. In a `_redirect` file
inside of the publish directory, I can write something like the following:

```
https://blog.acmiyaguchi.me/engineering/2020/01/24/* https://acmiyaguchi.me/blog/2021-01-24-sapper-export-and-preloaded-routes
https://blog.acmiyaguchi.me/engineering/2020/01/25/* https://acmiyaguchi.me/blog/2021-01-25-ring-wasm-tests
https://blog.acmiyaguchi.me/engineering/2020/01/26/* https://acmiyaguchi.me/blog/2021-01-26-gpuactive-backfill
```

These three rules show the Jekyll's pattern versus my scheme for posts. Since I
never posted more than one article a day, I could simply map all pages under a
category, year, month, and day to point to the new post location. These rules go
at the top of the file because the rules fall through as they go from most
restrictive to least restrictive.

Finally, I define a fall through rule to map the blog subdomain to the blog
route in the site. Since it is configured as an alias (i.e. it's equivalent to
my home domain), I would like to ignore serving the index.html at the root and
always redirect. I append an exclamation point to [shadow anything in the blog
subdomain
alias](https://docs.netlify.com/routing/redirects/rewrites-proxies/#shadowing).

```
https://blog.acmiyaguchi.me/* https://acmiyaguchi.me/blog 301!
```

Now I can rest easy that my old blog post links won't completely rot away.

If you're curious, here's the [`_redirects` file in my
repository at the time of writing](https://github.com/acmiyaguchi/acmiyaguchi.me/blob/d85170d142bffb80ada5f32e2194ce3ee6dafcb1/home/static/_redirects#L1-L13).
