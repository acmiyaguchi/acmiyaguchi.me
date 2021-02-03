<script>
  import { onMount } from "svelte";
  import { groupBy, sortBy } from "lodash";
  import Table from "../../components/Table.svelte";
  import Plot from "./Plot.svelte";

  let daily;
  let routes_all;
  let routes_daily = [];
  // note this is affected by the order of the files that are being fetched
  let modified;
  $: grouped = groupBy(routes_daily, "date");

  function getUrl(query) {
    return `https://storage.googleapis.com/acmiyaguchi/v1/query/${query}.json`;
  }

  async function fetchData(query) {
    let resp = await fetch(getUrl(query));
    // side-effects :)
    modified = resp.headers.get("Last-Modified");
    return await resp.json();
  }

  onMount(async () => {
    daily = await fetchData("logs_page_visits_daily");
    routes_all = await fetchData("logs_page_visits_routes_all");
    routes_daily = await fetchData("logs_page_visits_routes_daily");
  });

  function transformData(data) {
    let x = data.map(row => row.date);
    return [
      {
        x: x,
        y: data.map(row => row.total_visits),
        name: "total visits",
        mode: "lines+markers"
      },
      {
        x: x,
        y: data.map(row => row.unique_visits),
        name: "unique visits",
        mode: "lines+markers"
      }
    ];
  }
</script>

<svelte:head>
  <title>Analytics</title>
</svelte:head>

<h1>Analytics</h1>
<i>Last updated on {modified}</i>

<p>
  This page contains aggregates about site visitors. This is refreshed every 6
  hours starting at midnight UTC+00. Dates on this page are in the UTC-08
  timezone.
</p>

{#if daily}
  <Plot
    data={daily}
    transform={transformData}
    layout={{ title: 'Daily Visitors', legend: { orientation: 'h' } }} />
{/if}

<h2>Visits by Route - All Time</h2>
{#if routes_all}
  <Table
    data={routes_all}
    options={{ pagination: 'local', paginationSize: 10 }} />
{/if}

<h2>Visits by Route - Last 7 days</h2>
{#each Object.keys(grouped)
  .sort()
  .reverse() as dates}
  <h3>{dates}</h3>

  <Table
    data={grouped[dates]}
    options={{ pagination: 'local', paginationSize: 7 }}
    deleteColumns={['date']} />
{/each}
