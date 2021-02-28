<script>
  export let lib;
  $: Core = lib.Core;
  $: core = Core.new();
  $: console.log(core);
  $: display = core.get_display();
</script>

<svelte:head>
  <title>chip8 wasm demo</title>
</svelte:head>

<main>
  <h1>chip8 wasm demo</h1>
  <h2>Display Memory</h2>
  <textarea readonly>{display}</textarea>
</main>

<style>
  main {
    padding: 1em;
    max-width: 800px;
    margin: 0 auto;
  }

  textarea {
    width: 400px;
    height: 300px;
  }
</style>
