<script>
  import Table from "../../../components/Table.svelte";
  import Plot from "../../../components/Plot.svelte";
  import {
    mean,
    median,
    standardDeviation,
    medianAbsoluteDeviation
  } from "simple-statistics";

  export let data;
  $: delta = data.map(row => row.delta);

  const columns = [
    {
      name: "last update",
      format: row => row.last_update.slice(0, 16)
    },
    {
      name: "delta (hour)",
      format: row => row.delta
    },
    {
      name: "z-score (std)",
      format: row => row.scoreStd.toFixed(1)
    },
    {
      name: "status (std)",
      format: row => {
        if (row.scoreStd > 3) {
          return `<b style="background-color:yellow">partial-outage</b>`;
        } else {
          return "nominal";
        }
      },
      html: true
    },
    {
      name: "z-score (mad)",
      format: row => row.scoreMad.toFixed(1)
    },
    {
      name: "status (mad)",
      format: row => {
        if (row.scoreMad > 3) {
          return `<b style="background-color:yellow">partial-outage</b>`;
        } else {
          return "nominal";
        }
      },
      html: true
    }
  ];

  function transform(data) {
    return [
      {
        x: data.map(row => row.last_update),
        y: data.map(row => (row.scoreStd > 3 ? 1 : 0)),
        type: "line",
        name: "z-score (std) > 3",
        xaxis: "x"
      },
      {
        x: data.map(row => row.last_update),
        y: data.map(row => (row.scoreMad > 3 ? 1 : 0)),
        type: "line",
        name: "z-score (mad) > 3",
        xaxis: "x",
        yaxis: "y2"
      }
    ];
  }

  function summaryTable(delta) {
    return [
      {
        method: "mean",
        center: mean(delta).toFixed(1),
        deviation: standardDeviation(delta).toFixed(1)
      },
      {
        method: "median",
        center: median(delta).toFixed(1),
        deviation: medianAbsoluteDeviation(delta).toFixed(1)
      }
    ];
  }

  const layout = {
    title: "Time since last deploy outliers (z-score > 3)",
    height: 250,
    grid: {
      rows: 2,
      columns: 1,
      subplots: ["xy", "xy2"],
      roworder: "top to bottom"
    }
  };
</script>

{#if data && data.length > 0}
  <Table data={summaryTable(delta)} />

  <Plot {data} {transform} {layout} />

  <Table {data} {columns} paginationSize={7} />
{:else}Loading...{/if}
