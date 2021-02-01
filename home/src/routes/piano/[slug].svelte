<script context="module">
  export async function preload({ params }) {
    // the `slug` parameter is available because
    // this file is called [slug].html
    const res = await this.fetch(`piano/${params.slug}.json`);
    const data = await res.json();
    if (res.status === 200) {
      return { track: data, slug: params.slug };
    } else {
      this.error(res.status, data.message);
    }
  }
</script>

<script>
  import Player from "./Player.svelte";

  export let slug;
  export let track;
</script>

<svelte:head>
  <title>{slug}</title>
</svelte:head>

<h1>{slug}</h1>

<Player {track} />
