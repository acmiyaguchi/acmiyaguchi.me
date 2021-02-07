<script context="module">
  export async function preload() {
    let url = `https://storage.googleapis.com/acmiyaguchi/midi/manifest.json`;
    let resp = await this.fetch(url);
    let data = await resp.json();
    return {
      manifest: data
        .filter(row => row.name.endsWith(".mid"))
        .map(row => ({
          slug: row.name.split(".mid")[0],
          ...row
        }))
    };
  }
</script>

<script>
  import Body from "./Body.svx";
  export let manifest;
</script>

<Body {manifest} />
