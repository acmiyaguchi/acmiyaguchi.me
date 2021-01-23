<script>
  let days = [...Array(2).keys()].map(i => String(i + 1).padStart(2, "0"));
</script>

<ul class="nav">
  {#each days as day}
    <li class="nav-item">
      <a class="nav-link" rel="prefetch" href="aoc-2020/{day}">Day {day}</a>
    </li>
  {/each}
</ul>
