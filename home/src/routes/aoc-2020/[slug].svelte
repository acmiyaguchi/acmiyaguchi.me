<script context="module">
  export async function preload({ params }) {
    let { slug } = params;
    let res = await this.fetch(`aoc-2020/${slug}.pl`);
    let data = await res.text();
    if (res.status === 200) {
      return { content: data };
    } else {
      this.error(res.status, data.message);
    }
  }
</script>

<script>
  export let content;
</script>

<div class="content">
  <textarea>{content}</textarea>
</div>
