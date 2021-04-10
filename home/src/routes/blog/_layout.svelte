<script context="module">
  // Note that the layout also clashes with index page
  export async function preload(page) {
    if (page.path === "/blog") {
      return {};
    }
    let resp = await this.fetch(
      `blog/${page.path.split("/").reverse()[0]}.json`
    );
    return await resp.json();
  }
</script>

<script>
  import { Prism } from "prismjs";

  // Mdsvex has no idea what prism values are being used in each route, so I
  // have to do a bulk import of the css. This is suboptimal...
  import "prismjs/themes/prism.css";
  import "prismjs/components/prism-bash.min.js";
  import "prismjs/components/prism-docker.min.js";
  import "prismjs/components/prism-javascript.min.js";
  import "prismjs/components/prism-python.min.js";
  import "prismjs/components/prism-sql.min.js";
  import "prismjs/components/prism-scheme.min.js";
  import "katex/dist/katex.css";

  import dayjs from "dayjs";
  import localizedFormat from "dayjs/plugin/localizedFormat";
  dayjs.extend(localizedFormat);

  export let metadata;
</script>

<svelte:head>
  <title
    >{metadata
      ? `${metadata.title} | Anthony Miyaguchi's Blog`
      : "Blog Posts"}</title
  >
</svelte:head>
<main>
  {#if metadata}
    <h1>{metadata.title}</h1>
    <i>{dayjs(metadata.date).format("lll")}</i>
  {/if}

  <slot />
</main>

<style>
  main :global(img) {
    width: 100%;
  }

  main :global(table, th, td) {
    border: 1px solid black;
    border-collapse: collapse;
  }
</style>
