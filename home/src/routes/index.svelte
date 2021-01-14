<script>
  import geospiza from "../assets/geospiza.txt";
  import pubkey from "../assets/gpg-pubkey.txt";
  import { mandelbrot } from "./mandelbrot.js";
  let mandelbrotCanvas;
  $: mandelbrotCanvas && mandelbrot(mandelbrotCanvas);
</script>

<style>

</style>

<svelte:head>
  <title>Anthony Miyaguchi's corner of the internet</title>
</svelte:head>

<h1>Here be dragons</h1>
<p>Things to do, things to write.</p>

<p>
  You may also be interested in my
  <a href="https://blog.acmiyaguchi.me">blog</a>
  or
  <a href="https://github.com/acmiyaguchi">github proyfile</a>
  .
</p>

<canvas id="mandelbrot" width="480" height="320" bind:this={mandelbrotCanvas} />

<pre style="font: 10px/5px monospace;">{geospiza}</pre>

<pre>{pubkey}</pre>
