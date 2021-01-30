<script context="module">
  export async function preload() {
    let resp = await this.fetch("api/v1/blog-posts.json");
    return { metadata: await resp.json() };
  }
</script>

<script>
  import dayjs from "dayjs";
  import localizedFormat from "dayjs/plugin/localizedFormat";

  dayjs.extend(localizedFormat);

  export let metadata;
</script>

<svelte:head>
  <title>Blog Posts</title>
</svelte:head>

<h1>Blog Posts</h1>

<ul>
  {#each metadata as row}
    <li>
      <a href={`blog/${row.name}`}>
        {dayjs(row.date).format('ll')} - {row.title}
      </a>
    </li>
  {/each}
</ul>

<p>
  <a href="/">Go to the homepage.</a>
</p>
