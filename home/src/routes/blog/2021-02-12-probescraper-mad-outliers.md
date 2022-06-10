---
layout: post
title: Finding service outages with robust statistics
date: 2021-02-12T21:00:00-08:00
category: Engineering
tags:
  - monitoring
  - outliers
  - statistics
---

<script>
    import {onMount} from "svelte";
    import Table from "../../components/Table.svelte";
    import Plot from  "../../components/Plot.svelte";
    import Visualization from "./_assets/2021-02-12-viz.svelte"

    import {
        mean,
        median,
        standardDeviation,
        medianAbsoluteDeviation
    } from "simple-statistics";

    let rawData = []
    let data = []
    $: delta = data.map(row => row.delta);
    let dataDec = []
    let dataOct = []

    const columns = [
        {
            name: "last update",
            format: (row) => row.last_update.slice(0, 16)
        },
        {
            name: "delta (hour)",
            format: (row) => row.delta
        },
        {
            name: "day of week (int)",
            format: (row) => row.dayofweek
        },
        {
            name: "day of week",
            format: row =>
                [
                    "saturday",
                    "sunday",
                    "monday",
                    "tuesday",
                    "wednesday",
                    "thursday",
                    "friday"
                ][row.dayofweek]
        }
    ];

    function transform(data) {
        return [
            {
                x: data.map(row => row.last_update),
                y: data.map(row => row.delta),
                type: "line",
                name: "delta"
            }
        ]
    }

    function withScores(data) {
        // first the standard deviation
        let deltas = data.map(row => row.delta)
        let std = standardDeviation(deltas);
        let mad = medianAbsoluteDeviation(deltas)
        let k = 1.4826
        return data.map(row => ({
            ...row,
            scoreStd: (row.delta - mean(deltas))/std,
            scoreMad: (row.delta - median(deltas))/(k*mad)
        }));
    }

    onMount(async () => {
        let resp = await fetch("assets/2021-02-12/probeinfo_status.json");
        rawData = await resp.json();
        data = withScores(rawData);
        dataDec = withScores(rawData.filter(row => row.last_update.slice(5,7) == "11"))
        dataOct = withScores(rawData.filter(row => row.last_update.slice(5,7) == "10"))
    })
</script>

_Check out the [monitoring dashboard in action][monitoring]. Note that this post
is interactive and may not render correctly without Javascript._

The [Probe Scraper][probe-scraper] underpins the data schema infrastructure at
Mozilla. Every night, it trawls through Firefox Mercurial and Git
repositories, searching for registry files. The output powers the [Probe-Info
Service API][probe-info] (probe-info) that is used to [generate
schemas][schema-generator] and build [data dictionaries][glean-dictionary].

It is scheduled to run on business days (Monday to Friday UTC+00) on
[Airflow][airflow]. While there are notifications to the data engineering team
when the job inevitably fails for one reason or another, the status of the
[schema deployment pipeline][docs] has not always been clear from the outside. I
put together a [monitoring dashboard][monitoring] to address the lack of
visibility. The monitoring mechanism is not unlike a [watchdog timer][watchdog]
in embedded electronics, where it runs on a separate clock checking on the
health of the main system.

In this post, I'll write a little bit about how the probe-info service is
monitored and displayed for operational transparency. I'll focus the
discussion on the merits of statistical tools like the median absolute deviation
(MAD) for figuring out whether the probe-info service is up to date without
actually having access to the internals of the service.

[probe-scraper]: https://github.com/mozilla/probe-scraper
[probe-info]: https://mozilla.github.io/probe-scraper/
[schema-generator]: https://github.com/mozilla/mozilla-schema-generator
[glean-dictionary]: https://github.com/mozilla/glean-dictionary
[airflow]: https://github.com/mozilla/telemetry-airflow/
[docs]: https://docs.telemetry.mozilla.org/concepts/pipeline/schemas.html
[monitoring]: https://protosaur.dev/mps-deploys/
[watchdog]: https://en.wikipedia.org/wiki/Watchdog_timer

## Collecting monitoring data

Every 15 minutes, an [endpoint from the probe-info service][get-general] is
queried to obtain the last updated timestamp. This gets loaded into a BigQuery
table, then transformed and dumped into a JSON file. During this process, the
timestamps series is transformed into deltas representing the time since the
last update. In the SQL, we encode some of the business logic to consider the
lull of the weekends.

We expect to see five updates a week at a regular interval of 24 hours. Plotting
the data reveals apparent irregularities with the date. We consider anything
that takes longer than 24 business hours a partial-outage. It is a
partial-outage because the infrastructure continues to serve requests despite
out of date information about schemas.

[get-general]: https://mozilla.github.io/probe-scraper/#operation/getGeneral

{#if data.length > 0}

<div style="border: 1px solid black; padding: 1em;">

<Plot
{data}
transform={transform}
layout={{
    title:"Time since last deploy (hours)",
    height: 320,
    }}
/>

<br>

<details>
<summary>Click to reveal the SQL query</summary>

The query to transform the timestamps is straightforward. It's worth noting
that the delta is negative on the weekends which can lead to negative
aberrations when the Airflow is manually triggered outside of business days.

```sql
-- monitoring-queries:mozilla_pipeline_schemas.probeinfo_status
WITH extracted AS (
  SELECT
    last_update,
    TIMESTAMP_DIFF(
      coalesce(lead(last_update) OVER (ORDER BY last_update), current_timestamp()),
      last_update,
      hour
    ) AS delta,
    EXTRACT(dayofweek FROM last_update) AS dayofweek
  FROM
    mozilla_pipeline_schemas.probeinfo_meta
  ORDER BY
    last_update DESC
)
SELECT
  last_update,
  -- we subtract the weekend since the probe scraper is not running
  IF(dayofweek = 6, delta - 48, delta) AS delta,
  dayofweek
FROM
  extracted
```

</details>

<br>

<details>
<summary>Click to reveal tabular data</summary>
<Table {data} columns={columns} paginationSize={7} />
</details>

<br>

<details>
<summary>Click to reveal the first 3 rows of the raw JSON</summary>
<pre>{JSON.stringify(rawData.slice(0, 3), '', 2)}</pre>
</details>

</div>

{/if}

You can obtain a copy of the frozen output [here][status] or updated data
directly from the [monitoring dashboard][monitoring-json].

The large spike on 2021-01-28 was [due to a memory pressure issue][pr] that took
several days to resolve. This is the largest partial-outage in recorded history,
but not the only one. Between November and December, there are five outages in
total.

Is there a way to automatically detect whether there is currently a
partial-outage without knowing the intricacies of scheduling? It turns out we
can make this inference easily with the help of statistics.

[pr]: https://github.com/mozilla/probe-scraper/pull/267
[status]: assets/2021-02-12/probeinfo_status.json
[monitoring-json]: https://protosaur.dev/mps-deploys/data/mozilla_pipeline_schemas/probeinfo_status.json

## A refresher on statistics, are you MAD‽

To talk about outliers, we'll need to know how to describe the data and their
patterns.

### Standard statistics

You might already be familiar with these. If you are, feel free to skip ahead.
Otherwise:

<details>
<summary>Click here for an overview of mean, standard deviation, and z-score.</summary>

The mean ($\mu$) is the average of the dataset. We'll let $\text{avg}$ be the
the arithmetic mean, or the sum of all the values divided by the number of
values.

$$
\mu = \text{avg}(X) = \frac{
    \sum_{i=1}^n x_i
}{n}
$$

The [standard deviation][stddev] ($\sigma$) is a measure of spread which
quantifies the average distance from the mean. More precisely:

$$
\sigma = \sqrt{ \text{avg}((x_i - \mu)^2) }
$$

We can determine how many standard deviations a point is from the mean by
computing a [z-score][z-score] ($z$).

$$
z = \frac{x - \mu}{\sigma}
$$

For a set where $\mu=10$ and $\sigma=5$, the point $x=20$ has a score $z=2$,
while the point $x=5$ has a score $z=-1$.

</details>

### Robust statistics

We'll define robust equivalents of the mean, standard deviation, and z-score. A
robust statistic is less susceptible to the effects of outliers. The median
($\tilde{\mu}$) is the point in the sorted set of values, which we define as
$\text{med}$.

$$
\tilde{\mu} = \text{med}(X)
$$

The [median absolute deviation ($MAD$)][mad] is the median of differences from
the median, and a robust measure of spread.

$$
MAD = \text{med}(x - \tilde{\mu})
$$

Finally, we can compute a modified z-score ($\tilde{z}$) using $MAD$. We apply a
scale-factor $k$ that's appropriate for the distribution. I'll assume the data
is Gaussian (or normal) for lack of better prior understanding. According to
[Rosseeuw][rosseeuw], this means $k=1.4826$. [NIST suggests a similar
value][nist] of $k= 1 / 0.6745$. I'll be using the former for all calculations.

$$
\tilde{z} = \frac{x - \tilde{\mu}}{k \cdot MAD}
$$

[robust]: https://en.wikipedia.org/wiki/Robust_statistics
[stddev]: https://en.wikipedia.org/wiki/Standard_deviation
[z-score]: https://www.statisticshowto.com/probability-and-statistics/z-score/
[mad]: https://en.wikipedia.org/wiki/Median_absolute_deviation
[rosseeuw]: http://web.ipac.caltech.edu/staff/fmasci/home/astro_refs/BetterThanMAD.pdf
[nist]: https://www.itl.nist.gov/div898/handbook/eda/section3/eda35h.htm

## Detecting partial-outages on historical data

Now armed with the necessary statistical tools, let's run some analysis on
historical data to find partial-outages in the service. We'll mark point points
that are 3 deviations away from the center (mean or median) following the
[three-sigma rule of thumb][empirical].

[empirical]: https://en.wikipedia.org/wiki/68%E2%80%9395%E2%80%9399.7_rule

### All of history (7 partial-outages)

First, let's take a look at the data over the entire dataset so far,
representing approximately three months of data.

<details>
<summary>Click to reveal analysis</summary>
<div style="border: 1px solid black; padding: 1em;">
<Visualization data={data} />
</div>
</details>

The MAD-based threshold of 3 handily finds all the legitimate outages. If we had
set the threshold for the standard score to 1, we should obtain similar results.

### Month of November 2020 (3 partial-outages)

Now let's repeat it for November. This is a period with three
partial outages.

<details>
<summary>Click to reveal analysis</summary>
<div style="border: 1px solid black; padding: 1em;">
<Visualization data={dataDec} />
</div>
</details>

Again, the MAD-based threshold is working well. The optimal threshold for the
standard deviation is ~2, but the threshold from the previous section would work
too.

### Month of October 2020 (no outages)

And again for October. This was a perfect month without any outages 😊.

<details>
<summary>Click to reveal analysis</summary>
<div style="border: 1px solid black; padding: 1em;">
<Visualization data={dataOct} />
</div>
</details>

Everything is nominal. If our threshold were set to 1 here, we would
flag half of our dataset as unusual. The optimal threshold is closer to 2 in
this case.

## Thoughts and closing remarks

Robust measures of spread like MAD are good at finding outliers in data with
minimal tuning of the threshold. Note the standard deviation varies between
$0.5$ and $21.0$ hours depending on the period, whereas MAD does not go over
$1.0$ hour. Outliers can affect the variance of the standard deviation by a
large margin. This is less of a problem when we use a robust statistic like MAD,
which makes it useful when we don't know much about the data. While we can use
standard deviation to find service outages, we have to tune the z-score
threshold to meet our needs.

With a simple monitoring pipeline, we can detect outages in the absence of
further information. By looking at the time deltas between events, we can build
up a model that categorizes events into the usual and unusual. I've found that
MAD and the modified z-score are versatile tools, and I suggest trying them out
if you have the statistical need.
