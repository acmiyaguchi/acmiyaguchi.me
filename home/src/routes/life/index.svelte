<script>
  import life from "./life.scm";
  import { onMount } from "svelte";
  import BiwaScheme from "biwascheme";

  let biwascheme;

  onMount(() => {
    biwascheme = new BiwaScheme.Interpreter(e => console.log(e.message));
    biwascheme.evaluate(life);
  });
</script>

<h1>Game of life</h1>

<p>
  This is an implementation of the game of life in biwascheme. This is a work in
  progress, so things may not work as intended.
</p>

<p>
  <a href="/">Go to the homepage.</a>
</p>

<div id="canvas-container">
  <canvas width="400" height="400" id="life" />
</div>

<div>
  <button on:click={() => biwascheme.evaluate('(start)')}>start</button>
  <button on:click={() => biwascheme.evaluate('(stop)')}>stop</button>
  <button on:click={() => biwascheme.evaluate('(reset)')}>reset</button>
</div>

<div id="bs-console" />
