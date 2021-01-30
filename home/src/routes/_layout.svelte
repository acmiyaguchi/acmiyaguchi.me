<script>
  import { stores } from "@sapper/app";

  const { page } = stores();
  $: process.browser &&
    $page &&
    fetch(`https://storage.googleapis.com/acmiyaguchi/ping`).then();
</script>

<style>
  main,
  footer {
    font-family: Roboto, -apple-system, BlinkMacSystemFont, Segoe UI, Oxygen,
      Ubuntu, Cantarell, Fira Sans, Droid Sans, Helvetica Neue, sans-serif;
    max-width: 50em;
    background-color: white;
    margin: 0 auto;
    margin-bottom: 2em;
  }

  hr {
    max-width: 30em;
    border-top: 1px solid lightgray;
  }

  footer {
    text-align: center;
    margin-top: 2em;
  }
</style>

<main>
  <slot />
</main>

{#if $page.path != '/'}
  <hr />
  <footer>
    <a href="/">Take me to the homepage.</a>
  </footer>
{/if}
