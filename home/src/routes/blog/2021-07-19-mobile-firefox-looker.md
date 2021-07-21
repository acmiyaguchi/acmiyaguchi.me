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

Early in 2021, the data organization at Mozilla took a look into various
business intelligence tools in order to deliver value from data. After some
consideration, Looker was chosen as the tooling of choice. It was recently
acquired by Google Cloud and as such made a great fit with Mozilla's transition
to Google Cloud Platform. Looker provides the ability to create dashboards and
interactive views on data through a programmatic interface that is compiled down
to SQL dynamically. An explore provides an opportunity to summarize high
dimensional data into coherent data models that provide consistent views of the
world.

As part of the DUET (Data User Engagement Team) working group, some of my
day-to-day work involves building dashboards for visualizing user engagement
aspects of the Firefox product. A funnel captures a cohort of users as they flow
through various acquisition channels into the product. Typically, you'd
visualize the flow as a sankey or funnel plot, which allows you to view the
number of users that are retained at every step. By looking at this chart, you
can build intuition about bottlenecks or performance of compaigns.

Mozilla owns a few mobile products; there is Firefox for Android, Firefox for
iOS, and then Focus/Klar on both operating systems (also known as Klar in
certain regions). All of these products is instrumented using a telemetry system
called Glean. The foremost benefit of Glean is that it encapsulates many best
practices from years of instrumenting browsers; as such, all of the tables that
capture anonymized behavior activity are consistent across the products. One
valuable idea from this set-up is that writing a query for a single product
should allow it to extend to others without too much extra work. Looker allows
us to take advantage of congruent schemas with the ability to templatize
queries.

## Peculiarities of Data Sources

Before jumping off into implementing a dashboard, it's important to discuss the
quality of the data sources that are being used in this project. The way that
the app stores and Mozilla count users are different, and account for a
significant amount of inconsistencies. Certain policies about the granularity of
data can also lead to difficults connecting various sources of data together.

For example, in the Play Store, there is no way for Mozilla to tie the a Glean
client back to the Google account that was counted as as a user that installed
Firefox. Each Glean client is assigned a new identifier for each device, whereas
Google only counts new installs by account (which may have several devices).
These two numbers are correlated over a day, but we don't have the ability to
track a single user across this boundary. Instead, we have to rely on the
relative proportions over time to see how performance is doing. There are even
more complications when trying to compare numbers between Android and iOS. Where
as the Play Store may show the number of accounts that have visited a page, the
Apple App Store shows the total number of page visits instead. Apple also only
reports users that have opted into data collection, which under-represents the
total number of users.

These differences can be confusing to people who are not intimately familiar
with the pecularities of these different systems. An important part of putting
together this view is therefore documenting and educating the users of the
dashboard so they have a rough understanding of the data.

## ETL Pipeline

The pipeline looks something like this:

1. Baseline anonymized behavioral data flows into the
   `org_mozilla_firefox.baseline` table.
1. A derived `org_mozilla_firefox.baseline_clients_first_seen` table is created
   from the baseline table.
1. A Looker explore references the `baseline_clients_first_seen` table in a
   parameterized SQL query, alongside data from the Google Play Store.
1. A dashboard references the explore to communicate important statistics at
   first glance, alongside configurable paramters.

## Building a Looker Dashboard

There are three important components to building a Looker dashboard: a view, an
explore, and a dashboard. In this project, we consider three files:

- `mobile_android_country.view.lkml`
  - Contains the templated SQL query for preprocessing the data, parameters for
    the query, and a specification of available metrics and dimensions.
- `mobile_android_country.explore.lkml`
  - Contains joins across views, and any aggregate tables suggested by Looker
- `mobile_android_country.dashboard.lkml`
  - Generated dashboard configuration for purposes of version-control.

### View

The view is the bulk of data modeling work. Here, there are a few fields that
are particularly important to keep mind of. There is a derived table alongside
parameters, dimensions, and measures.

The derived table section allows us to specify the shape of the data that is
visible to Looker. We can either refer to a table or view directly from a
supported database (e.g. BigQuery), or we can write a query against that
database. One of the nicest features is that Looker will automatically re-run
the derived table as necessary. The query can also be parameterized, allowing
for dynamic views on the data.

```lkml
derived_table: {
  sql: with period as (SELECT ...),
      play_store_retained as (
          SELECT
          Date AS submission_date,
          COALESCE(IF(country = "Other", null, country), "OTHER") as country,
          SUM(Store_Listing_visitors) AS first_time_visitor_count,
          SUM(Installers) AS first_time_installs
          FROM
            `moz-fx-data-marketing-prod.google_play_store.Retained_installers_country_v1`
          CROSS JOIN
            period
          WHERE
            Date between start_date and end_date
            AND Package_name IN ('org.mozilla.{% parameter.app_id %}')
          GROUP BY 1, 2
      ),
      ...
      ;;
}
```

Above is the derived table section for the android query. Here, we're looking at
the `play_store_retained` statement inside of the common table expression (CTE).
Inside of this sql block, we have access to everything that's available to
BigQuery. We also have access to parameters that are defined in the view.

```lkml
# Allow swapping between various applications in the dataset
parameter: app_id {
  description: "The name of the application in the `org.mozilla` namespace."
  type:  unquoted
  default_value: "fenix"
  allowed_value: {
    value: "firefox"
  }
  allowed_value: {
    value: "firefox_beta"
  }
  allowed_value: {
    value:  "fenix"
  }
  allowed_value: {
    value: "focus"
  }
  allowed_value: {
    value: "klar"
  }
}
```

These parameters can be controlled from within an explore and trigger updates to
the view. These are referenced using the liquid templating syntax:

```sql
AND Package_name IN ('org.mozilla.{% parameter.app_id %}')
```

For Looker to be aware of the shape of the final query result, we must define
dimensions and metrics corresponding to columns in the result. Here is the final
statement in the CTE from above:

```sql
select
    submission_date,
    country,
    max(play_store_updated) as play_store_updated,
    max(latest_date) as latest_date,
    sum(first_time_visitor_count) as first_time_visitor_count,
    ...
    sum(activated) as activated
from play_store_retained
full join play_store_installs
using (submission_date, country)
full join last_seen
using (submission_date, country)
cross join period
where submission_date between start_date and end_date
group by 1, 2
order by 1, 2
```

Generally in an aggregate query like this, the grouping columns will become
dimensions while the aggregate values become metrics. A dimension is a column
that we can filter or drill down into to get a different slice of the data
model:

```lkml
dimension: country {
  description: "The country code of the aggregates. The set is limited by those reported in the play store."
  type: string
  sql: ${TABLE}.country ;;
}
```

Note that we can refer to the derived table using the `${TABLE}` variable (not
unlike interpolating a variable in a bash script).

A measure is a column that represents metric of some kind. This value is
typically dependent on the dimensions.

```lkml
measure: first_time_visitor_count {
  description: "The number of first time visitors to the play store."
  type: sum
  sql: ${TABLE}.first_time_visitor_count ;;
}
```

We must ensure that all dimensions and columns are declared to make them
available to explores. Looker provides a few ways to create these fields
automatically. If you create a view directly from a table, Looker can
autogenerate these from the schema. Likewise, the SQL editor has options to
generate a view file directly. Whatever the method may be, some manual
modification will be necessary in order to build a clean data model for use.

### Explore

One of the more compelling features of Looker is the ability for folks to drill
down into data models without being able to write SQL. They provide an interface
where the dimensions and measures can be manipulated and plot in an easy to use
graphical interface. To do this, we need to declare which view to use. Often,
just declaring the explore is sufficient:

```lkml
include: "../views/*.view.lkml"

explore: mobile_android_country {
}
```

We include the view from a location relative to the explore file. Then we name
an explore that shares the same name as the view. Once this is done, we should
be able to explore the data in the dropdown.

The explore can also be used to join multiple views and to provide default
parameters. In this project, we utilize a country view that we can use to group
countries into various buckets. For example, we may have a group for North
American countries, another for European coutries, and so forth.

```lkml
explore: mobile_android_country {
  join: country_buckets {
    type: inner
    relationship: many_to_one
    sql_on:  ${country_buckets.code} = ${mobile_android_country.country} ;;
  }
  always_filter: {
    filters: [
      country_buckets.bucket: "Overall"
    ]
  }
}
```

Finally, the explore is also the place where Looker will materialize certain
portions of the view. This is only relevant when copying the materialized
segments from the exported dashboard code. An example of what this looks like
follows:

```lkml
aggregate_table: rollup__submission_date__0 {
  query: {
    dimensions: [
      # "app_id" is filtered on in the dashboard.
      # Uncomment to allow all possible filters to work with aggregate awareness.
      # app_id,
      # "country_buckets.bucket" is filtered on in the dashboard.
      # Uncomment to allow all possible filters to work with aggregate awareness.
      # country_buckets.bucket,
      # "history_days" is filtered on in the dashboard.
      # Uncomment to allow all possible filters to work with aggregate awareness.
      # history_days,
      submission_date
    ]
    measures: [activated, event_installs, first_seen, first_time_visitor_count]
    filters: [
      # "country_buckets.bucket" is filtered on by the dashboard. The filter
      # value below may not optimize with other filter values.
      country_buckets.bucket: "tier-1",
      # "mobile_android_country.app_id" is filtered on by the dashboard. The filter
      # value below may not optimize with other filter values.
      mobile_android_country.app_id: "firefox",
      # "mobile_android_country.history_days" is filtered on by the dashboard. The filter
      # value below may not optimize with other filter values.
      mobile_android_country.history_days: "7"
    ]
  }

  # Please specify a datagroup_trigger or sql_trigger_value
  # See https://looker.com/docs/r/lookml/types/aggregate_table/materialization
  materialization: {
    sql_trigger_value: SELECT CURRENT_DATE();;
  }
}
```

### Dashboard

## Strengths and Weaknesses of Looker

Now that I've gone through the process of building a dashboard end-to-end, I
have a general idea of why Looker was chosen as the BI tool for the data
organization. Here are a few points that summarize my experience and the
take-aways from putting together this dashboard.

### Parameterized queries allow flexibility across similar tables

A table is similar when it shares the same schema and can be re-used in the same
query. In another project, I worked with Glean-instrumented data by
parameterizing SQL queries using Jinja2 and running queries multiple times.
Looker effectively brings this process closer to runtime and allows for the ETL
and visualization to live in the same platform. I'm impressed by how well it
works in practice. The combination of consistent data models in bigquery-etl
(e.g. `clients_first_seen`) and the ability to parameterize based on app-id was
surprisingly straightforward. The dashboard is able to switch between Firefox
for Android and Focus for Android without a hitch, even though they are two
separate products with two separate datasets in BigQuery.

I can envision many places where we may not want to precompute all results ahead
of time, but instead a subset of columns or dates on-demand. The costs of
precomputing and materializing data is non-negligable, especially for large
expensive queries that are viewed once in a blue moon or dimensions that fall in
the long tail. Templating and parameters provide a great way to build these into
the data model without having to resort to manually written SQL.

### LookML in version control allows makes room for software engineering best practices

While Looker appeals to the non-technical crowd, it also affords many
conveniences for the data practitioners who are familiar with software
development practices.

Every change to Looker can be checked into version control (e.g. git). Being
able to create branches and work on multiple features in parallel has been handy
at time. It's relieving to have the ability to make changes in my own instance
of the Looker files when trying out something new without having to lose my
place. The ability to configure views, explores, and dashboards through the
configuration files allows for the process of creating new dashboards to
incorporate many best-practices like code review.

In addition, it's nice to be able to use a real editor for mass revision. I was
able to create a new dashoard for iOS data that paralleled the android dashboard
by copying over files, modifying the SQL in the view, and making a few edits to
the dashboard code directly. This would not have been possible if the dashboard
were required to be modified by hand.

### Workflow management is clunky for deploying new dashboards

While there are many upsides to having explores and dashboards in code, there
are several pain points while working with the Looker interface.

In particular, the workflow for editing a dashboard goes something like this.
First you copy the dashboard into a personal folder that you can edit. You make
whatever modifications to that dashboard using the UI. Afterwards, you export
the result and copy-paste it into the dashboard code. While not ideal, this
prevents the dashboard from going out of sync from the one that you're editing
directly (since there won't be conflicts between the UI and the code in version
control). However, it would be nice if it were possible to edit the dashboard
directly instead of making a copy with Looker performing any conflict resolution
internally.

There have been moments where I've had to fight with the built in git interface
built into Looker's development mode. Reverting a commit to a particular branch
or dealing with merge conflicts can be an absolute nightmare. If you do happen
to the project into a local environment, you aren't able to validate your
changes locally (you'll need to push, pull into looker, and then validate and
fix anything). Finally, the formatting option is stuck behind a keyboard
shortcut, while the keyboard shortcut is already being used by the browser.

## Conclusion: Iterating on Feedback

Simply building a dashboard is not enough to demonstrate that it has value. It's
important gather feedback from peers and stakeholders to gather feedback and to
determine the best path forward. There are some things that benefit from having
a concrete implementation though; there differences between different platforms
and inconsistencies in the data that may only appear after putting together an
initial draft of a project.

The funnel dashboard, while hitting goals of making data across app stores and
our user populations visible, has room for improvement. Having this dashboard
located in Looker makes the process of iterating that much easier though. If
changes need to be made, editing the dashboard can typically be done quickly if
you're acclimated to the structure of the project. The feedback cycle of
changing the query to seeing the results is fairly low, and can be rolled back
quickly too. The tool is promising, and I look forward to seeing how it
transforms the data landscape at Mozilla.

## Resources

- https://looker.com/
- https://looker.com/blog/google-closes-looker-acquisition
- https://github.com/mozilla/looker-spoke-default/pull/52
- https://github.com/mozilla/looker-spoke-default/pull/54
