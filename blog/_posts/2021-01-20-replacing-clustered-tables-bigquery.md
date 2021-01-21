---
layout: post
title: Clustering Existing BigQuery Tables
date:   2021-01-20 17:00:00 -0800
category: Engineering
tags:
    - bigquery
---

[Clustering in
BigQuery](https://cloud.google.com/bigquery/docs/clustered-tables) can help
reduce the cost of querying large tables. Here's are a few commands for testing
the behavior when replacing the results of a destination table with a series of
queries.

First we populate a `test` table in a `test` dataset. Then we try to replace the
table with clustering enabled.

```bash
% bq query --destination_table test.test "select 1 as a, 2 as b"

Waiting on bqjob_r77b43cc4637cb7a0_00000177213c92cc_1 ... (0s) Current status: DONE
+---+---+
| a | b |
+---+---+
| 1 | 2 |
+---+---+

% bq query --destination_table test.test --use_legacy_sql=false \
    --replace --clustering_fields=a,b "select 1 as a, 2 as b"

BigQuery error in query operation: Error processing job
'amiyaguchi-dev:bqjob_r3e6624e9e42cacd_000001772141adc6_1': Incompatible table
partitioning specification. Expects partitioning specification none, but input
partitioning specification is  clustering(a,b)
```

This fails because the result set does not match how the table was originally
created (i.e. without a clustering specification). So let's try this again.

```bash
% bq rm test.test
rm: remove table 'amiyaguchi-dev:test.test'? (y/N) y

% bq query --destination_table test.test --use_legacy_sql=false \
    --replace --clustering_fields=a,b "select 1 as a, 2 as b"

Waiting on bqjob_r4a8550d8dc7e314_000001772143df53_1 ... (0s) Current status: DONE
+---+---+
| a | b |
+---+---+
| 1 | 2 |
+---+---+
```

We can check that it's being clustered.

```bash
% bq show test.test

Table amiyaguchi-dev:test.test

   Last modified       Schema       Total Rows   Total Bytes   Expiration   Time Partitioning   Clustered Fields   Labels
 ----------------- --------------- ------------ ------------- ------------ ------------------- ------------------ --------
  20 Jan 11:27:14   |- a: integer   1            16                                             a, b
                    |- b: integer
```

In summary, you're going to need to redefine your tables in order to take
advantage of new clustering features.