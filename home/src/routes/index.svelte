<script context="module">
  export async function preload() {
    let git_logs = await this.fetch("api/v1/git-logs.txt");
    let blog_posts = await this.fetch("api/v1/blog-posts.json?limit=7");
    return { logs: await git_logs.text(), metadata: await blog_posts.json() };
  }
</script>

<script>
  import FrontMatter from "./FrontMatter.svx";
  import geospiza from "../assets/geospiza.txt";
  import pubkey from "../assets/gpg-pubkey.txt";
  import { mandelbrot } from "./mandelbrot.js";

  export let logs;
  export let metadata;

  let mandelbrotCanvas;
  $: mandelbrotCanvas && mandelbrot(mandelbrotCanvas);
</script>

<svelte:head>
  <title>Anthony Miyaguchi's corner of the internet</title>
</svelte:head>

<FrontMatter {logs} {metadata} />

<h2>Miscellaneous</h2>

<ul>
  <li>
    <a href="life">Game of life in scheme</a>
  </li>
  <li>
    <a href="aoc-2020">Advent of Code 2020 (in progress)</a>
  </li>
  <li>
    <a href="blog">Port of my main blog (in progress)</a>
  </li>
</ul>

<canvas id="mandelbrot" width="480" height="320" bind:this={mandelbrotCanvas} />

<pre style="font: 10px/5px monospace;">{geospiza}</pre>

<pre>{pubkey}</pre>
