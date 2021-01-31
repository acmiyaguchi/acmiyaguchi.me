<script context="module">
  export async function preload({ params }) {
    // the `slug` parameter is available because
    // this file is called [slug].html
    const res = await this.fetch(`piano/${params.slug}.json`);
    const data = await res.json();
    if (res.status === 200) {
      return { track: data };
    } else {
      this.error(res.status, data.message);
    }
  }
</script>

<script>
  import Player from "./Player.svelte";

  export let track;
</script>

<Player {track} />
