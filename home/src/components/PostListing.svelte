<script>
  import dayjs from "dayjs";
  import localizedFormat from "dayjs/plugin/localizedFormat";

  dayjs.extend(localizedFormat);

  export let metadata;
</script>

{#if metadata && metadata.length}
  <ul>
    {#each metadata as row}
      <li>
        <a href={`blog/${row.name}`}>
          {dayjs(row.date).format('ll')} - {row.title}
        </a>
      </li>
    {/each}
  </ul>
{:else}
  <i>There are currently no posts. Stay tuned!</i>
{/if}
