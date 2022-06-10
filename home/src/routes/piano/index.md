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
    export let manifest = []
</script>

# Piano recordings

This is a place where I archive recordings of my piano practices. I hope to see
a tangible improvements in my skill one day. I am recording midi output from a
[Casio
LK-94TV]()
into [LMMS](https://lmms.io/).

<ul>
{#each manifest as item}
<li><a href={`piano/${item.slug}`}>{item.slug}</a></li>
{/each}
</ul>

[casio]: https://www.casio.com/products/archive/electronic-musical-instruments/lighted-keys/lk-94tv
