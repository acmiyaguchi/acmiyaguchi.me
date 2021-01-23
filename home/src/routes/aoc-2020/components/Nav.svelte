<script>
  export let index = false;
  let days = [...Array(2).keys()].map(i => String(i + 1).padStart(2, "0"));
</script>

<ul class="nav">
  {#if !index}
    <li class="nav-item">
      <a class="nav-link" rel="prefetch" href="aoc-2020">
        Advent of Code 2020 Home
      </a>
    </li>
  {/if}
  {#each days as day}
    <li class="nav-item">
      <a class="nav-link" rel="prefetch" href="aoc-2020/day-{day}">Day {day}</a>
    </li>
  {/each}
</ul>
