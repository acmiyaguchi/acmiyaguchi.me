<script>
  import { chunk } from "lodash";
  export let data = [];
  export let paginationSize = null;
  export let columns = null;

  $: columns = columns || (data.length > 0 && autoColumns(data));
  let idx = 0;
  $: chunked = paginationSize ? chunk(data, paginationSize) : [data];
  $: total = data.length;
  $: pages = chunked.length;

  function autoColumns(data) {
    return Object.keys(data[0]).map(key => ({
      name: key,
      format: row => (row[key] == undefined ? "" : row[key]),
      html: false
    }));
  }

  function prev() {
    if (idx > 0) {
      idx--;
    }
  }
  function next() {
    if (idx < pages - 1) {
      idx++;
    }
  }
</script>

<style>
  table,
  th,
  td {
    border: 1px solid black;
  }
</style>

<div>
  <table cellpadding="5">
    <tr>
      {#each columns as column}
        <th>{column.name}</th>
      {/each}
    </tr>
    {#each chunked[idx] as row}
      <tr>
        {#each columns as column}
          <td>
            {#if column.html}
              {@html column.format(row)}
            {:else}{column.format(row)}{/if}
          </td>
        {/each}
      </tr>
    {/each}
  </table>
  <div>
    {#if pages > 1}
      <button disabled={!(idx > 0)} on:click={prev}>Prev</button>
      <button disabled={!(idx < pages - 1)} on:click={next}>Next</button>
      <span>{total} rows - page {idx + 1} of {pages}</span>
    {/if}
  </div>
</div>
