<script context="module">
  export async function preload() {
    let git_logs = await this.fetch("api/v1/git-logs.txt");
    let blog_posts = await this.fetch("api/v1/blog-posts.json");
    return {
      logs: await git_logs.text(),
      metadata: (await blog_posts.json()).slice(0, 7)
    };
  }
</script>

<script>
    import PostListing from "../components/PostListing.svelte";
    import Mandelbrot from "../components/mandelbrot/Mandelbrot.svelte";
    import geospiza from "../assets/geospiza.txt";
    import pubkey from "../assets/gpg-pubkey.txt";

    export let logs;
    export let metadata;
</script>

<svelte:head>

  <title>Anthony Miyaguchi's corner of the internet</title>
</svelte:head>

# Here be dragons 🐉

_Things to do, things to write. This is Anthony Miyaguchi's personal site._

Now more than halfway through the [COVID-19 pandemic][pandemic], I've been using
the time stolen away from productive hobbies like [Brazilian jiu-jitsu][bjj]
into incredibly [grindy MMORPGs][mmorpg] and small programming projects.

I write software for [Planet] on the storage and jobs system supporting
satellite data pipelines. I previously wrote open-source software for Mozilla as
a Data Engineer. I recently started a Masters in Computer Science at Georgia
Tech at the start of 2022. You may be interested in my [github
profile](https://github.com/acmiyaguchi).

[pandemic]: https://en.wikipedia.org/wiki/COVID-19_pandemic
[bjj]: https://en.wikipedia.org/wiki/Brazilian_jiu-jitsu
[mmorpg]: https://en.wikipedia.org/wiki/Massively_multiplayer_online_role-playing_game
[planet]: https://www.planet.com/

## Recent Blog Posts

Sometimes, I write things. Here are the last 7 things that I've posted.

See all of my posts on the [blog index](blog). Subscribe to the [rss feed
here](blog/rss.xml), too.

<PostListing {metadata} />

## Miscellaneous Content

Here is an assortment of content on the site.

- [Site analytics](analytics), statistics about the visitors to each page
- [Advent of Code 2020](aoc-2020), in prolog, egads -- up to day 7
- [Recordings of my piano practices](piano)
- [Toastmasters](toastmasters), and my experience becoming a better public
  speaker
- [BirdCLEF 2021](birdclef-2021), a Kaggle competition I started and left
  unfinished
- [BirdCLEF 2022](https://github.com/acmiyaguchi/birdclef-2022), a Kaggle
  competition that I finished with a team at the DS@GT club and submitted a
  working notes paper

## Site Changelog

I keep track of the site [on Github][source]. Here are the [last 10
commits][commits].

<pre style="overflow:auto">
{logs}
</pre>

[source]: https://github.com/acmiyaguchi/acmiyaguchi.me/tree/main/home
[commits]: https://github.com/acmiyaguchi/acmiyaguchi.me/commits/main/home

## Digital Potpourri

<Mandelbrot />

<pre style="font: 10px/5px monospace;">{geospiza}</pre>

<pre>{pubkey}</pre>
