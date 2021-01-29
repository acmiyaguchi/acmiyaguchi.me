<script>
  import { stores } from "@sapper/app";

  const { page } = stores();
  $: process.browser &&
    $page &&
    fetch(`https://storage.googleapis.com/acmiyaguchi/ping`).then();
</script>

<style>
  main {
    font-family: Roboto, -apple-system, BlinkMacSystemFont, Segoe UI, Oxygen,
      Ubuntu, Cantarell, Fira Sans, Droid Sans, Helvetica Neue, sans-serif;
    max-width: 800px;
    background-color: white;
    margin: 0 auto;
  }
</style>

<main>
  <slot />
</main>
