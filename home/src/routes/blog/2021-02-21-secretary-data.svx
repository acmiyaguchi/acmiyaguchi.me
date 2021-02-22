---
layout: post
title: A look at the Secretary role through data
date: 2021-02-21T23:00:48-08:00
category: Toastmasters
tags:
  - roles
  - secretary
---

<script>
  import Table from "../../components/Table.svelte"
  import Plot from "../../components/Plot.svelte"
  import minutes from "./_assets/2021-02-21-minutes.tsv";
  
</script>

<style>
  img[alt=revision-history] {
    max-height: 400px;
    width: auto;
  }
</style>

Being a secretary for a Toastmasters club is a meticulous job. There's quite a
bit of quantitative data that I can look at to figure out how well I'm providing
my club with timely minutes. In this post, I'll show data gathered from Google
Docs and Email that shows some of the efforts I've spent creating meeting
minutes. So far, I've written over a dozen minutes, with several more dozen to
go.

## Time spent editing the minutes

I create the minutes from a [perpetual
stew](https://en.wikipedia.org/wiki/Perpetual_stew) of a document that I
continue to make copies of. The revision history in Google Docs can give a good
idea of the time I spent on the minutes. I chose a recent document highlighting
my typical workflow, divided into distinct phases of note-taking and revising.

<div style="text-align:center">

![revision-history](/assets/2021-02-21/google-docs-revision.png)

</div>

I spent Monday (February 8) writing the majority of the minutes during the
meeting note-taking. This involves capturing the attendees, who spoke, and roles
that were taken. I write quite a bit here. At a later time on Sunday (February
14), I spent about an hour and 20 minutes editing the document before sending it
out to the group at 9:12 PM via the mailing list. It's handy having all of these
timestamps in digital documents to keep track of time.

I would say that this is a typical week for me, which ends up being ~3 hours of
work. It'd be nice to measure the variance in this data through the other 13
documents, but data entry is not the most fun way to spend an evening (the plots
take that spot!). This is more than I'd like to spend on the minutes, which I
think could be cut by another hour or so as I develop the muscle and make
optimizations to the process.

## Number of words/characters in the minutes

A Google Doc has the benefit of keeping everything in version control that can
be referenced later. I compared revisions of the same document to see the effect
on the document length. At the end of the meeting, the number of words was 1377,
and the number of characters was 8119. After I got through revising the
document, it was whittled down to 1120 words and 6819 characters.

Being wordy is easy; being concise is hard. The majority of my revision is
removing content and making the summaries short but to the point. I think this
document represents my work as Secretary so far. The revision efforts are to
boil down my notes into something that can be referenced in the future -- a
time-consuming process for sure.

## Delay in the publishing of minutes

The last source of data is the email timestamps from meeting minutes on the
mailing list. In the 14 documents that I've written, the median time to delivery
is five days. I consider my commitments to consistent timeliness a success as long
as this doesn't go beyond a week. There's certainly room for improvement,
though.

<Plot data={minutes}
transform={data => [{
x: data.map(row => row.days),
type: "box"
}]}
layout={{
  title:"boxplot of published minutes delay (days)",
  height: 250
}} />

<Plot data={minutes}
transform={data => [{
x: data.map(row => row.meeting_date),
y: data.map(row => row.days),
type: "line"
}]}
layout={{
  title:"history of published minutes delay (days)",
  height: 250
}}
/>

<details>
<summary>Click here to show the raw data</summary>
<Table data={minutes} />
</details>

## So what?

The data provides insight into the note-taking process, but it doesn't entirely
encapsulate the quality of my role as a Secretary. I want to continue to reduce
the effort it takes to continue producing the same quality of work. Data
plays a part in tracking progress, but it's not a meaningful goal in
itself.

In my next post, I'd like to write more about some of the goals that I'd like to
achieve in the next few months as I continue in the rhythm of writing and
rewriting.
