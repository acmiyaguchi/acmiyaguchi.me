---
layout: post
title: Building a mobile funnel dashboard in Looker
date: 2021-03-05T00:38:00-08:00
category: Engineering
tags:
  - Looker
  - LookML
  - SQL
  - BigQuery
---

Here's a link to the Jira tickets that no-one can see: https://mozilla-hub.atlassian.net/browse/DS-1541

Early in 2021, the data organization at Mozilla took a look into various business intelligence tools
in order to deliver value from data. After some consideration, Looker was chosen as the tooling of
choice. It was recently acquired by Google Cloud and as such made a great fit with Mozilla's
transition to Google Cloud Platform. Looker provides the ability to create dashboards and
interactive views on data through a programmatic interface that is compiled down to SQL dynamically.
An explore provides an opportunity to summarize high dimensional data into coherent data models that
provide consistent views of the world.

As part of the DUET (Data User Engagement Team) working group, some of my day-to-day work involves
building dashboards for visualizing user engagement aspects of the Firefox product. A funnel
captures a cohort of users as they flow through various acquisition channels into the product.
Typically, you'd visualize the flow as a sankey or funnel plot, which allows you to view the number
of users that are retained at every step. By looking at this chart, you can build intuition about
bottlenecks or performance of compaigns.

Mozilla owns a few mobile products; there is Firefox for Android, Firefox for iOS, and then
Focus/Klar on both operating systems (also known as Klar in certain regions). All of these products
is instrumented using a telemetry system called Glean. The foremost benefit of Glean is that it
encapsulates many best practices from years of instrumenting browsers; as such, all of the tables
that capture anonymized behavior activity are consistent across the products. One valuable idea from
this set-up is that writing a query for a single product should allow it to extend to others without
too much extra work. Looker allows us to take advantage of congruent schemas with the ability to
templatize queries.

## Peculiarities of Data Sources

Before jumping off into implementing a dashboard, it's important to discuss the quality of the data
sources that are being used in this project. The way that the app stores and Mozilla count users are
different, and account for a significant amount of inconsistencies. Certain policies about the
granularity of data can also lead to difficults connecting various sources of data together.

For example, in the Play Store, there is no way for Mozilla to tie the a Glean client back to the
Google account that was counted as as a user that installed Firefox. Each Glean client is assigned a
new identifier for each device, whereas Google only counts new installs by account (which may have
several devices). These two numbers are correlated over a day, but we don't have the ability to
track a single user across this boundary. Instead, we have to rely on the relative proportions over
time to see how performance is doing. There are even more complications when trying to compare
numbers between Android and iOS. Where as the Play Store may show the number of accounts that have
visited a page, the Apple App Store shows the total number of page visits instead. Apple also only
reports users that have opted into data collection, which under-represents the total number of
users.

These differences can be confusing to people who are not intimately familiar with the pecularities
of these different systems. An important part of putting together this view is therefore documenting
and educating the users of the dashboard so they have a rough understanding of the data.

## ETL Pipeline

The pipeline looks something like this:

1. Baseline anonymized behavioral data flows into the `org_mozilla_firefox.baseline` table.
1. A derived `org_mozilla_firefox.baseline_clients_first_seen` table is created from the baseline
   table.
1. A Looker explore references the `baseline_clients_first_seen` table in a parameterized SQL query,
   alongside data from the Google Play Store.
1. A dashboard references the explore to communicate important statistics at first glance, alongside
   configurable paramters.

### Building a Looker Dashboard

## Strengths and Weaknesses of Looker

## Conclusion: Iterating on Feedback

- https://looker.com/
- https://looker.com/blog/google-closes-looker-acquisition
- https://github.com/mozilla/looker-spoke-default/pull/52
- https://github.com/mozilla/looker-spoke-default/pull/54
