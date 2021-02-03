<script context="module">
  export async function preload() {
    let git_logs = await this.fetch("api/v1/git-logs.txt");
    let blog_posts = await this.fetch("api/v1/blog-posts.json");
    return {
      logs: await git_logs.text(),
      metadata: (await blog_posts.json()).slice(0, 7)
    };
  }
</script>

<script>
  import Body from "./Body.svx";

  export let logs;
  export let metadata;
</script>

<svelte:head>
  <title>Anthony Miyaguchi's corner of the internet</title>
</svelte:head>

<Body {logs} {metadata} />
