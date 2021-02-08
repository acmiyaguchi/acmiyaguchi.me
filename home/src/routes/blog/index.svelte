<script context="module">
  export async function preload() {
    let resp = await this.fetch("api/v1/blog-posts.json");
    return { metadata: await resp.json() };
  }
</script>

<script>
  import PostListing from "./PostListing.svelte";
  export let metadata;
</script>

<style>
  :global(table, tr, td) {
    border-collapse: collapse;
  }
</style>

<svelte:head>
  <title>Blog Posts</title>
</svelte:head>

<h1>Blog Posts</h1>

<PostListing {metadata} />
