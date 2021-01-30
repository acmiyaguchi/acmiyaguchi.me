<script context="module">
  export async function preload({ params }) {
    // the `slug` parameter is available because
    // this file is called [slug].html
    const res = await this.fetch(`blog/${params.slug}.json`);
    const data = await res.json();
    if (res.status === 200) {
      return data;
    } else {
      this.error(res.status, data.message);
    }
  }
</script>

<script>
  import { Prism } from "prismjs";

  // Because this is going over an api, and mdsvex has no idea what prism values
  // are being used in each route, I have to do a bulk import of the css. This
  // is suboptimal...
  import "prismjs/themes/prism.css";
  import "prismjs/components/prism-bash.min.js";
  import "prismjs/components/prism-docker.min.js";
  import "prismjs/components/prism-javascript.min.js";
  import "prismjs/components/prism-python.min.js";
  import "prismjs/components/prism-sql.min.js";
  import "prismjs/components/prism-scheme.min.js";
  import dayjs from "dayjs";
  import localizedFormat from "dayjs/plugin/localizedFormat";

  dayjs.extend(localizedFormat);

  export let content;
  export let metadata;
</script>

<style>
  .content :global(img) {
    width: 100%;
  }
</style>

<svelte:head>
  <title>{metadata.title}</title>
</svelte:head>

<div class="content">
  <h1>{metadata.title}</h1>
  <i>{dayjs(metadata.date).format('lll')}</i>

  {@html content.html}

</div>
