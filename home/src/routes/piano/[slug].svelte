<script context="module">
  export async function preload({ params }) {
    return {
      slug: params.slug
    };
  }
</script>

<script>
  import Player from "./Player.svelte";

  export let slug;
  $: src = `https://storage.googleapis.com/acmiyaguchi/midi/${slug}.mid`;
</script>

<svelte:head>
  <title>{slug}</title>
</svelte:head>

<h1>{slug}</h1>

<Player {src} />
