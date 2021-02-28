<script>
  import { onMount } from "svelte";
  import wasm from "../chip8-core/Cargo.toml";

  export let Chip8Core;

  onMount(async () => {
    Chip8Core = await wasm();
    Chip8Core.start();
  });
</script>

<svelte:head>
  <title>chip8 wasm demo</title>
</svelte:head>

<main>
  <h1>chip8 wasm demo</h1>
  <canvas id="canvas" />
</main>

<style>
  main {
    padding: 1em;
    max-width: 800px;
    margin: 0 auto;
  }
</style>
