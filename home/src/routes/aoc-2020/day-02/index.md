<script>
  import Nav from "../components/Nav.svelte"
  import Editor from "../components/Editor.svelte";
  import solution from "./solution.pl";
</script>

# Day 2

_2020-01-21_

[Problem](https://adventofcode.com/2020/day/2)

This problem was fun because it involved some real parsing. Being able to treat
strings directly as Prolog atoms with `term_string/2` was a neat way to
deconstruct the first column in the solution (e.g. `1-3`) directly into a pair.

Before coming to use `include/3`, I tried out `maplist/3` with some moderate
success by adding an extra variable to `verify`. For some reason, the
interpreter was unhappy with it. `include/3` is a much nicer way to define the
list anyhow. I was also surprised that I had to write my own predicate to count
the number of times a particular item exists within a list. I might have been
able to get away with this using `include/3`, but I'm not proficient enough yet
to know.

## Solution

<Editor text={solution} />

## Index

<Nav />
