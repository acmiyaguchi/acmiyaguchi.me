<script>
  import life from "./life.scm";
  import { onMount } from "svelte";

  let biwascheme;

  onMount(() => {
    biwascheme = new BiwaScheme.Interpreter(e => console.log(e.message));
    biwascheme.evaluate(life);
  });
</script>

<div id="canvas-container">
  <canvas width="400" height="400" id="life" />
</div>

<div>
  <button on:click={() => biwascheme.evaluate('(start)')}>start</button>
  <button on:click={() => biwascheme.evaluate('(stop)')}>stop</button>
  <button on:click={() => biwascheme.evaluate('(reset)')}>reset</button>
</div>

<div id="bs-console" />
