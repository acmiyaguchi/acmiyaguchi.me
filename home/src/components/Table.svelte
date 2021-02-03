<script>
  import { onMount } from "svelte";
  import Tabulator from "tabulator-tables";
  import "tabulator-tables/dist/css/tabulator_simple.min.css";

  export let data;
  export let options = {};
  export let deleteColumns = [];

  let tableElement;

  onMount(async () => {
    let table = new Tabulator(tableElement, {
      data: data,
      autoColumns: true,
      layout: "fitColumns",
      ...options
    });
    for (let column of deleteColumns) {
      table.deleteColumn(column);
    }
  });
</script>

<div bind:this={tableElement} />
