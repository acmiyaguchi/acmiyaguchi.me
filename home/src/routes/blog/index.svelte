<script context="module">
  export async function preload() {
    let resp = await this.fetch("api/v1/blog_posts.json");
    return { metadata: await resp.json() };
  }
</script>

<script>
  export let metadata;
</script>

<p>This is a work in progress.</p>

<ul>
  {#each metadata as row}
    <li>
      <a href={`blog/${row.title}`}>{row.date} - {row.title}</a>
    </li>
  {/each}
</ul>

<p>
  <a href="/">Go to the homepage.</a>
</p>
