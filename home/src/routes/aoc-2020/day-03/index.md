<script>
  import Nav from "../components/Nav.svelte"
  import Editor from "../components/Editor.svelte";
  import solution from "./solution.pl";
</script>

# Day 3

_2020-01-23_

[Problem](https://adventofcode.com/2020/day/3)

I'm starting to get more proficient writing Prolog. The first part was nothing to write home about. For `isTree/4`, I end up using two definitions that only differ by whether an accumulator value is incremented. In the definition of `isTree2/6`, I end up using an if predicate `(Cond -> X; Y)` which saves a few lines of repetition.

I spent the most time trying to debug `main2/2` where the toboggan is traversing down a steeper slope i.e. going right 1 and down 2. I thought that this was an issue in `atPos2/4`, and I tried modifying the Index to take into account the current position in the y-axis. The problem was that I was iterating through the list one at a time, so I wrote `skipList/3` to skip over elements of the original array.

## Solution

<Editor text={solution} />

## Index

<Nav />
