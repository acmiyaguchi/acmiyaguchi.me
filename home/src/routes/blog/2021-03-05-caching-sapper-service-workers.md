---
layout: post
title: Caching in Sapper Service Workers
date: 2021-03-05T00:38:00-08:00
category: Engineering
tags:
  - web development
  - sapper
  - ssr
  - caching
---

[Sapper](https://sapper.svelte.dev) uses a [service worker that proxies fetch
events][proxy] from content in the web browser. This is great because the
application can now work offline. On the other hand, it doesn't take advantage
of the default browser caching mechanisms. This means a request with
cache-control headers will always be fetched, regardless of whether the content
is cache-able. In this post, I cover a few ways that the service worker in the
Sapper template can be modified to handle different caching behaviors.

## Prioritize assets from the network

The [default behavior][proxy] is to fetch assets from the network, otherwise
falling back on the cache. The `timestamp` variable is set by Sapper as the
service worker's build time and is useful for invalidating the cache in-case we
make a mistake.

```javascript
/**
 * Fetch the asset from the network and store it in the cache.
 * Fall back to the cache if the user is offline.
 */
async function fetchAndCache(request) {
  const cache = await caches.open(`offline${timestamp}`);

  try {
    const response = await fetch(request);
    cache.put(request, response.clone());
    return response;
  } catch (err) {
    const response = await cache.match(request);
    if (response) return response;

    throw err;
  }
}
```

We always get fresh content from the network this way, with the benefit of
offline support. If you're using server-side rendering with caching on requests,
this may be the way to go.

## Prioritize assets from the cache

The online experience can suffer from making these requests over and over again,
especially if the content is static. One solution is to [cache all
requests][cache-everything]. The above function can be modified as so:

```javascript
/**
 * Fetch the asset from the cache, otherwise try from the network.
 */
async function cacheOrFetch(request) {
  const cache = await caches.open(`offline${timestamp}`);

  const response = await cache.match(request);
  if (response) return response;

  const response = await fetch(request);
  cache.put(request, response.clone());
  return response;
}
```

This may work well depending on your use-case. In particular, this might be
great for a static blog that does no client-side rendering or fetches.

## Invalidate the cache based on response headers

The one problem with caching everything is that you may serve stale content if
you use a different static hosting solution (e.g., S3 or GCS). The [cache API
documentation on MDN][cache-api] explicitly calls this out:

> The caching API doesn't honor HTTP caching headers.

So we have to implement our cache-invalidation logic if we want to use this
alongside content that may change over time. Since I've built most of my tooling
around Google Cloud Platform, I know I can rely on the `expires` response header
when using content served from a Cloud Storage bucket. Here's an implementation
of cache invalidation that uses `fetchAndCache` as a primitive.

```javascript
/**
 * Caches that expire based on expires headers
 */
async function expirableFetchOrCache(request) {
  const cache = await caches.open(`expirable${timestamp}`);
  let response = await cache.match(request);

  if (response) {
    // GCS sets expires headers
    let expires = response.headers.get("expires");
    let stale = !expires || new Date(expires).getTime() < new Date().getTime();
    if (!stale) return response;
  }

  // otherwise, try from the network and the offline cache
  response = await fetchAndCache(request);
  cache.put(request, response.clone());
  return response;
}
```

We've created a wrapper function with its own `expirable` cache. On every
successful match into the local cache, we simply check whether the response is
stale to see if we need to hit the network. Reusing the `fetchAndCache` from the
Sapper template affords us the same offline experience as before.

## Final thoughts

It's nice that Sapper and Svelte are thin abstractions over necessary web
technologies and easy to grok when you need to change the default behavior. The
behavior of the service worker is not so apparent, though; going from a pure
Svelte application to Sapper leads to some appreciable differences in
performance because of these caching issues. Being an effective web developer
sometimes requires digging deeper into the complexities of networking and
caching. Hopefully, these three code snippets can help debug your own problems.

[proxy]: https://github.com/sveltejs/sapper-template/blob/820f6533340d975218cf7593eef6fe72412764f3/src/service-worker.js#L35-L52
[cache-everything]: https://dev.to/mweissen/sapper-with-cache-first-4jnl
[cache-api]: https://developer.mozilla.org/en-US/docs/Web/API/Cache
