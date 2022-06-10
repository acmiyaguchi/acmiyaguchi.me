<script>
  import { stores } from "@sapper/app";
  import Navbar from "../components/Navbar.svelte";

  const { page } = stores();
  $: process.browser &&
    $page &&
    fetch(`https://storage.googleapis.com/acmiyaguchi/ping`, {
      cache: "no-store",
    }).then();
</script>

<main>
  <Navbar
    path={$page.path
      .split("/")
      .slice(1)
      .map((s) => s.trim())
      .filter((s) => s)}
  />
  <slot />
</main>

{#if $page.path != "/"}
  <hr />
  <footer>
    <a href="/">Take me to the homepage.</a>
  </footer>
{/if}

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
