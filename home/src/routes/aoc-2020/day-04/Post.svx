<script>
  import Nav from "../components/Nav.svelte"
  import Editor from "../components/Editor.svelte";
  import solution from "./solution.pl";
</script>

# Day 4

_2020-01-23_

[Problem](https://adventofcode.com/2020/day/4)

This day was straightforward, but it did introduce me to some new data
structures. I made use of association lists which can be created from pairs
using [`list_to_assoc/2`][swi-assoc] ([relevant StackOverflow][so-assoc]). I
think this will turn out to be quite useful in the future. Overall, the data
validation pieces a while to implement just because there are so many
conditions. I imagined that it would be less verbose to specify something like
this in Prolog, but the amount of intermediate variables that need to be
declared puts a hamper on things. `height_valid/1` was the one predicate that
seemed overly verbose because strings need to be converted to chars to strip out
the units, then converted into a string again before being cast into an integer.
It'd be nice to be able to call multiple predicates in the same statement, but I
can't quite put my finger on what exactly that syntax would look like.

The use of [char codes][swi-char] was easier than I anticipated, and it reminded
me of my first computer science class of directly manipulating strings. I would
rather have done this using regular expressions, but I don't think regex is
built into the swi-prolog standard library.

Another small thing I figured out -- I can declare facts directly inside of the
predicate. For example, my test data could have been refactored as so:

```prolog
test_a("a:b
         e:f

c:d".)
```

I've also found out a way to make better unit tests on predicates by declaring
predicates that can't be called by the user starting them with `:-`. This was
handy when I was looking for a tiny bug in the solution for the second part. It
turned out I was missing "grn" as a valid eye color!

[so-assoc]: https://stackoverflow.com/questions/60687102/how-to-get-value-from-key-value-pair-in-prolog
[swi-assoc]: https://www.swi-prolog.org/pldoc/man?section=assoc-creation
[swi-char]: https://www.swi-prolog.org/pldoc/man?predicate=char_code/2

## Solution

<Editor text={solution} />

## Index

<Nav />
