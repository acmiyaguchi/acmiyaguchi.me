<script>
  import { onMount } from "svelte";
  import { groupBy, sortBy } from "lodash";

  let header = ["path", "total_visits", "unique_visits"];
  let data = [];
  $: grouped = groupBy(data, "date");

  onMount(async () => {
    let resp = await fetch(
      `https://storage.googleapis.com/acmiyaguchi/v1/query/logs_page_visits.json`
    );
    // TODO: document bigquery schemas of each view/table
    data = await resp.json();
  });
</script>

<style>
  table,
  th,
  td {
    border: 1px solid black;
  }
</style>

<svelte:head>
  <title>Analytics</title>
</svelte:head>

<h1>Analytics</h1>

<p>
  This page contains aggregates about site visitors. This is refreshed several
  times a day.
</p>

{#each Object.keys(grouped)
  .sort()
  .reverse() as dates}
  <h2>{dates}</h2>

  <table>
    <thead>
      <tr>
        {#each header as col}
          <th>{col}</th>
        {/each}
      </tr>
    </thead>
    <tbody>
      {#each sortBy(grouped[dates], ['total_visits']).reverse() as row}
        <tr>
          {#each header as col}
            <td>
              {#if col == 'path'}
                <a href={row[col]}>{row[col]}</a>
              {:else}{row[col]}{/if}
            </td>
          {/each}
        </tr>
      {/each}
    </tbody>
  </table>
{/each}
