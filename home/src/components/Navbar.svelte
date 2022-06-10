<script>
  export let path = [];
</script>

<nav>
  <div>
    <a href="/">home</a>
    {#each path as part, i}
      <span class="sep">/</span>
      <a href={"/" + path.slice(0, i + 1).join("/")}>{part}</a>
    {/each}
  </div>
</nav>

<style>
  .sep {
    padding: 5px;
  }
</style>
