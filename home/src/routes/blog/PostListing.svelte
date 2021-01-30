<script>
  import dayjs from "dayjs";
  import localizedFormat from "dayjs/plugin/localizedFormat";

  dayjs.extend(localizedFormat);

  export let metadata;
</script>

<ul>
  {#each metadata as row}
    <li>
      <a href={`blog/${row.name}`}>
        {dayjs(row.date).format('ll')} - {row.title}
      </a>
    </li>
  {/each}
</ul>
