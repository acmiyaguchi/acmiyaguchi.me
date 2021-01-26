<script>
  import Nav from "../components/Nav.svelte"
  import Editor from "../components/Editor.svelte";
  import solution from "./solution.pl";
</script>

# Day 5

_2020-01-24_

[Problem](https://adventofcode.com/2020/day/5)

This problem really suits logic programming. Decoding the binary-encoded seat pass was straightforward. I enjoyed how simple it is to define the search as a series of rules. I've gotten the hang of adding predicates as embedded unit tests in the code. I don't think I'll ever use Prolog in a production environment, so I can live with the inefficiencies of this since it's so easy to test. I can just run `true.` in the query window to evaluate whether these tests pass.

## Solution

<Editor text={solution} />

## Index

<Nav />
