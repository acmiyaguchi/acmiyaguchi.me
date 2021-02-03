<script>
  import { onMount } from "svelte";
  import { groupBy, sortBy } from "lodash";
  import Table from "../../components/Table.svelte";

  let all_data = [];
  let daily_data = [];
  // note this is affected by the order of the files that are being fetched
  let modified;
  $: grouped = groupBy(daily_data, "date");

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
    all_data = await fetchData("logs_page_visits_routes_all");
    daily_data = await fetchData("logs_page_visits_routes_daily");
  });
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

<h2>Visits by Route - All Time</h2>
{#if all_data.length}
  <Table
    data={all_data}
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
