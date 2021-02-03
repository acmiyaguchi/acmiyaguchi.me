<script>
  import { onMount } from "svelte";

  export let data;
  export let transform = res => res;
  export let layout = {};
  let plotElement;

  onMount(async () => {
    // TOOD: compile this in a local repository to speed up builds
    const { default: Plotly } = await import("plotly.js/lib/core");
    Plotly.newPlot(
      plotElement,
      transform(data),
      {
        margin: {
          l: 50,
          r: 0,
          b: 50
        },
        ...layout
      },
      { responsive: true }
    );
  });
</script>

<div bind:this={plotElement} />
