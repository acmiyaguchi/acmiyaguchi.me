<script context="module">
  export async function preload() {
    let resp = await this.fetch("api/v1/blog-posts.json");
    let posts = await resp.json();
    return { metadata: posts.filter(p => p.category == "Toastmasters") };
  }
</script>

<script>
  import Body from "./Body.svx";
  export let metadata;
</script>

<Body {metadata} />
