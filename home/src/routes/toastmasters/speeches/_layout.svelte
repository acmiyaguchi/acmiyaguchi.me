<script context="module">
  // Note that the layout also clashes with index page
  export async function preload(page) {
    let resp = await this.fetch(
      `toastmasters/speeches/${page.path.split("/").reverse()[0]}.json`
    );
    return await resp.json();
  }
</script>

<script>
  import dayjs from "dayjs";
  import localizedFormat from "dayjs/plugin/localizedFormat";
  dayjs.extend(localizedFormat);

  export let metadata;
</script>

<svelte:head>
  <title>{metadata.title}</title>
</svelte:head>
<main>
  {#if metadata}
    <h1>{metadata.title}</h1>
    <i>{dayjs(metadata.date).format('lll')}</i>
  {/if}

  <slot />
</main>
