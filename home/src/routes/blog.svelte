<script context="module">
  export async function preload() {
    let resp = await this.fetch("api/v1/blog-posts.json");
    return { metadata: await resp.json() };
  }
</script>

<script>
  // this component lives in the root, otherwise there are issues
  // mounting and remounting the blog pages.
  // https://github.com/sveltejs/sapper/issues/1278
  import PostListing from "../components/PostListing.svelte";
  export let metadata;
</script>

<style>
  :global(table, tr, td) {
    border-collapse: collapse;
  }
</style>

<h1>Blog Posts</h1>

<PostListing {metadata} />
