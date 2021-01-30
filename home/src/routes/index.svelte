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

<canvas id="mandelbrot" width="480" height="320" bind:this={mandelbrotCanvas} />

<pre style="font: 10px/5px monospace;">{geospiza}</pre>

<pre>{pubkey}</pre>
