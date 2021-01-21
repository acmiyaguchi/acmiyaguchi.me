---
layout: post
title: Walking through `mozaggregator2bq`
date:   2020-03-16 17:00:00 -0800
category: Engineering
tags:
    - spark
    - bigquery
    - postgresl
---

Let's take a look at backfilling the mozaggregator database into BigQuery. This
is a set of scripts that converts the database backing [Telemetry Measurement
Dashboard](https://telemetry.mozilla.org/new-pipeline/dist.html) to an
accessible BigQuery table. The
[`mozaggregator2bq`](https://github.com/acmiyaguchi/mozaggregator2bq) contains
the scripts and any other background necessary to follow along.

Let's kick it off:

```bash
START_DS=2015-06-01 END_DS=2020-03-01 bin/backfill
```

From this, I'll cut out a single iteration so it's easier to follow along.

```bash
+ run_day build_id 20160919
+ local aggregate_type=build_id
+ local ds_nodash=20160919
+ local input=data/build_id/20160919
+ local intermediate=data/parquet/build_id/20160919
+ local output=gs://mozaggregator2bq/data/build_id/20160919
```

First we call into a function to process the build ids for `2016-09-19`.

```bash
+ gsutil stat gs://mozaggregator2bq/data/build_id/20160919/_SUCCESS
No URLs matched: gs://mozaggregator2bq/data/build_id/20160919/_SUCCESS
```

We check for for the existence of a `_SUCCESS` file. This way, we don't repeat
any work if we run the script for this date range again.

```bash
+ AGGREGATE_TYPE=build_id
+ DS_NODASH=20160919
+ scripts/pg_dump_by_day
pg_dump: last built-in OID is 16383
pg_dump: reading extensions
pg_dump: identifying extension members
pg_dump: reading schemas
pg_dump: reading user-defined tables
pg_dump: reading user-defined functions
pg_dump: reading user-defined types
pg_dump: reading procedural languages
pg_dump: reading user-defined aggregate functions
pg_dump: reading user-defined operators
pg_dump: reading user-defined access methods
pg_dump: reading user-defined operator classes
pg_dump: reading user-defined operator families
pg_dump: reading user-defined text search parsers
pg_dump: reading user-defined text search templates
pg_dump: reading user-defined text search dictionaries
pg_dump: reading user-defined text search configurations
pg_dump: reading user-defined foreign-data wrappers
pg_dump: reading user-defined foreign servers
pg_dump: reading default privileges
pg_dump: reading user-defined collations
pg_dump: reading user-defined conversions
pg_dump: reading type casts
pg_dump: reading transforms
pg_dump: reading table inheritance information
pg_dump: reading event triggers
pg_dump: finding extension tables
pg_dump: finding inheritance relationships
pg_dump: reading column info for interesting tables
pg_dump: finding the columns and types of table "public.build_id_nightly_51_20160919"
pg_dump: finding the columns and types of table "public.build_id_nightly_52_20160919"
pg_dump: finding the columns and types of table "public.build_id_aurora_50_20160919"
pg_dump: finding the columns and types of table "public.build_id_aurora_51_20160919"
pg_dump: finding the columns and types of table "public.build_id_beta_50_20160919"
pg_dump: finding the columns and types of table "public.build_id_release_49_20160919"
pg_dump: finding the columns and types of table "public.build_id_nightly_50_20160919"
pg_dump: finding the columns and types of table "public.build_id_beta_49_20160919"
```

There is an individual table for each submission date and build id.
Here, we're batching up all of the relevant tables from the database by using a glob.
`pg_dump` has found the relevant tables that match the glob for `build_id_*_20160919`.

```bash
pg_dump: flagging inherited columns in subtables
pg_dump: reading indexes
pg_dump: reading indexes for table "public.build_id_nightly_51_20160919"
pg_dump: reading indexes for table "public.build_id_nightly_52_20160919"
pg_dump: reading indexes for table "public.build_id_aurora_50_20160919"
pg_dump: reading indexes for table "public.build_id_aurora_51_20160919"
pg_dump: reading indexes for table "public.build_id_beta_50_20160919"
pg_dump: reading indexes for table "public.build_id_release_49_20160919"
pg_dump: reading indexes for table "public.build_id_nightly_50_20160919"
pg_dump: reading indexes for table "public.build_id_beta_49_20160919"
pg_dump: reading extended statistics
pg_dump: reading constraints
pg_dump: reading triggers
pg_dump: reading rewrite rules
pg_dump: reading policies
pg_dump: reading publications
pg_dump: reading publication membership
pg_dump: reading subscriptions
pg_dump: reading dependency data
pg_dump: saving encoding = UTF8
pg_dump: saving standard_conforming_strings = on
pg_dump: saving search_path =
pg_dump: dumping contents of table "public.build_id_aurora_50_20160919"
pg_dump: dumping contents of table "public.build_id_aurora_51_20160919"
pg_dump: dumping contents of table "public.build_id_beta_49_20160919"
pg_dump: dumping contents of table "public.build_id_beta_50_20160919"
pg_dump: dumping contents of table "public.build_id_nightly_50_20160919"
pg_dump: dumping contents of table "public.build_id_nightly_51_20160919"
pg_dump: dumping contents of table "public.build_id_nightly_52_20160919"
pg_dump: dumping contents of table "public.build_id_release_49_20160919"
```

We get a set of gzipped data with a table of contents. We [parse the
bytes](https://github.com/acmiyaguchi/mozaggregator2bq/blob/be82395e18c961b6679177f09a79323e5391c1a6/scripts/pg_dump_to_parquet.py#L117-L169)
in the `toc.dat` in order to map the table name back to the relevant `*.dat.gz`
files.

```bash
$ tree -h data/build_id/20160919

data/build_id/20160919
├── [ 6.9M]  497374.dat.gz
├── [  71K]  497375.dat.gz
├── [ 2.3M]  497376.dat.gz
├── [  11M]  497377.dat.gz
├── [ 8.5K]  497378.dat.gz
└── [ 4.8K]  toc.dat
0 directories, 6 files
```

Now we start [processing the dump in Spark](https://github.com/acmiyaguchi/mozaggregator2bq/blob/be82395e18c961b6679177f09a79323e5391c1a6/scripts/pg_dump_to_parquet.py#L35-L84).
This will convert the text dumps into a columnar structure.

```bash
+ echo 'running for data/parquet/build_id/20160919'
+ bin/submit-local scripts/pg_dump_to_parquet.py --input-dir data/build_id/20160919 --output-dir data/parquet/build_id/20160919
running for data/parquet/build_id/20160919
++ python -c 'import pyspark; print(pyspark.__path__[0])'
+ SPARK_HOME=/home/amiyaguchi/mozaggregator2bq/venv/lib64/python3.6/site-packages/pyspark
+ spark-submit --master 'local[*]' --conf spark.driver.memory=8g --conf spark.sql.shuffle.partitions=16 scripts/pg_dump_to_parquet.py --input-dir data/build_id/20160919 --output-dir data/parquet/build_id/20160919
```

Text processing is not too intensive, so it can be run on a laptop efficiently.

```bash
20/03/13 20:58:10 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Using Spark's default log4j profile: org/apache/spark/log4j-defaults.properties
20/03/13 20:58:10 INFO SparkContext: Running Spark version 2.4.4
20/03/13 20:58:10 INFO SparkContext: Submitted application: pg_dump_to_parquet.py
20/03/13 20:58:10 INFO SecurityManager: Changing view acls to: amiyaguchi
20/03/13 20:58:10 INFO SecurityManager: Changing modify acls to: amiyaguchi
20/03/13 20:58:10 INFO SecurityManager: Changing view acls groups to:
20/03/13 20:58:10 INFO SecurityManager: Changing modify acls groups to:
20/03/13 20:58:10 INFO SecurityManager: SecurityManager: authentication disabled; ui acls disabled; users  with view permissions: Set(amiyaguchi); groups with view permissions: Set(); users  with modify permissions: Set(amiyaguchi); groups with modify permissions: Set()
20/03/13 20:58:11 INFO Utils: Successfully started service 'sparkDriver' on port 46647.
20/03/13 20:58:11 INFO SparkEnv: Registering MapOutputTracker
20/03/13 20:58:11 INFO SparkEnv: Registering BlockManagerMaster
20/03/13 20:58:11 INFO BlockManagerMasterEndpoint: Using org.apache.spark.storage.DefaultTopologyMapper for getting topology information
20/03/13 20:58:11 INFO BlockManagerMasterEndpoint: BlockManagerMasterEndpoint up
20/03/13 20:58:11 INFO DiskBlockManager: Created local directory at /tmp/blockmgr-08dedbcc-cffe-4051-9637-20ad300e2d90
20/03/13 20:58:11 INFO MemoryStore: MemoryStore started with capacity 4.1 GB
20/03/13 20:58:11 INFO SparkEnv: Registering OutputCommitCoordinator
20/03/13 20:58:11 INFO Utils: Successfully started service 'SparkUI' on port 4040.
20/03/13 20:58:11 INFO SparkUI: Bound SparkUI to 0.0.0.0, and started at http://instance-2.c.mozaggregator2bq.internal:4040
20/03/13 20:58:11 INFO Executor: Starting executor ID driver on host localhost
20/03/13 20:58:11 INFO Utils: Successfully started service 'org.apache.spark.network.netty.NettyBlockTransferService' on port 39195.
20/03/13 20:58:11 INFO NettyBlockTransferService: Server created on instance-2.c.mozaggregator2bq.internal:39195
20/03/13 20:58:11 INFO BlockManager: Using org.apache.spark.storage.RandomBlockReplicationPolicy for block replication policy
20/03/13 20:58:11 INFO BlockManagerMaster: Registering BlockManager BlockManagerId(driver, instance-2.c.mozaggregator2bq.internal, 39195, None)
20/03/13 20:58:11 INFO BlockManagerMasterEndpoint: Registering block manager instance-2.c.mozaggregator2bq.internal:39195 with 4.1 GB RAM, BlockManagerId(driver, instance-2.c.mozaggregator2bq.internal, 39195, None)
20/03/13 20:58:11 INFO BlockManagerMaster: Registered BlockManager BlockManagerId(driver, instance-2.c.mozaggregator2bq.internal, 39195, None)
20/03/13 20:58:11 INFO BlockManager: Initialized BlockManager: BlockManagerId(driver, instance-2.c.mozaggregator2bq.internal, 39195, None)
20/03/13 20:58:11 INFO SharedState: Setting hive.metastore.warehouse.dir ('null') to the value of spark.sql.warehouse.dir ('file:/home/amiyaguchi/mozaggregator2bq/spark-warehouse').
20/03/13 20:58:11 INFO SharedState: Warehouse path is 'file:/home/amiyaguchi/mozaggregator2bq/spark-warehouse'.
20/03/13 20:58:12 INFO StateStoreCoordinatorRef: Registered StateStoreCoordinator endpoint
20/03/13 20:58:15 INFO FileSourceStrategy: Pruning directories with:
20/03/13 20:58:15 INFO FileSourceStrategy: Post-Scan Filters:
20/03/13 20:58:15 INFO FileSourceStrategy: Output Data Schema: struct<dimension: string, aggregate: string>
20/03/13 20:58:15 INFO FileSourceScanExec: Pushed Filters:
20/03/13 20:58:15 INFO ParquetFileFormat: Using default output committer for Parquet: org.apache.parquet.hadoop.ParquetOutputCommitter
20/03/13 20:58:15 INFO FileOutputCommitter: File Output Committer Algorithm version is 1
20/03/13 20:58:15 INFO SQLHadoopMapReduceCommitProtocol: Using user defined output committer class org.apache.parquet.hadoop.ParquetOutputCommitter
20/03/13 20:58:15 INFO FileOutputCommitter: File Output Committer Algorithm version is 1
20/03/13 20:58:15 INFO SQLHadoopMapReduceCommitProtocol: Using output committer class org.apache.parquet.hadoop.ParquetOutputCommitter
20/03/13 20:58:15 INFO CodeGenerator: Code generated in 218.92042 ms
20/03/13 20:58:15 INFO CodeGenerator: Code generated in 21.033364 ms
20/03/13 20:58:15 INFO CodeGenerator: Code generated in 15.353879 ms
20/03/13 20:58:15 INFO CodeGenerator: Code generated in 7.696307 ms
20/03/13 20:58:15 INFO ContextCleaner: Cleaned accumulator 4
20/03/13 20:58:15 INFO ContextCleaner: Cleaned accumulator 1
20/03/13 20:58:15 INFO ContextCleaner: Cleaned accumulator 5
20/03/13 20:58:15 INFO ContextCleaner: Cleaned accumulator 3
20/03/13 20:58:15 INFO MemoryStore: Block broadcast_0 stored as values in memory (estimated size 285.7 KB, free 4.1 GB)
20/03/13 20:58:15 INFO MemoryStore: Block broadcast_0_piece0 stored as bytes in memory (estimated size 23.4 KB, free 4.1 GB)
20/03/13 20:58:15 INFO BlockManagerInfo: Added broadcast_0_piece0 in memory on instance-2.c.mozaggregator2bq.internal:39195 (size: 23.4 KB, free: 4.1 GB)
20/03/13 20:58:15 INFO SparkContext: Created broadcast 0 from parquet at NativeMethodAccessorImpl.java:0
20/03/13 20:58:15 INFO FileSourceScanExec: Planning scan with bin packing, max size: 18073596 bytes, open cost is considered as scanning 4194304 bytes.
20/03/13 20:58:15 INFO CodeGenerator: Code generated in 13.897457 ms
20/03/13 20:58:15 INFO CodeGenerator: Code generated in 10.328908 ms
20/03/13 20:58:16 INFO SparkContext: Starting job: parquet at NativeMethodAccessorImpl.java:0
20/03/13 20:58:16 INFO DAGScheduler: Registering RDD 10 (parquet at NativeMethodAccessorImpl.java:0)
20/03/13 20:58:16 INFO DAGScheduler: Registering RDD 15 (parquet at NativeMethodAccessorImpl.java:0)
20/03/13 20:58:16 INFO DAGScheduler: Registering RDD 21 (parquet at NativeMethodAccessorImpl.java:0)
20/03/13 20:58:16 INFO DAGScheduler: Got job 0 (parquet at NativeMethodAccessorImpl.java:0) with 1 output partitions
20/03/13 20:58:16 INFO DAGScheduler: Final stage: ResultStage 3 (parquet at NativeMethodAccessorImpl.java:0)
20/03/13 20:58:16 INFO DAGScheduler: Parents of final stage: List(ShuffleMapStage 2)
20/03/13 20:58:16 INFO DAGScheduler: Missing parents: List(ShuffleMapStage 2)
20/03/13 20:58:16 INFO DAGScheduler: Submitting ShuffleMapStage 0 (MapPartitionsRDD[10] at parquet at NativeMethodAccessorImpl.java:0), which has no missing parents
20/03/13 20:58:16 INFO MemoryStore: Block broadcast_1 stored as values in memory (estimated size 21.8 KB, free 4.1 GB)
20/03/13 20:58:16 INFO MemoryStore: Block broadcast_1_piece0 stored as bytes in memory (estimated size 10.5 KB, free 4.1 GB)
20/03/13 20:58:16 INFO BlockManagerInfo: Added broadcast_1_piece0 in memory on instance-2.c.mozaggregator2bq.internal:39195 (size: 10.5 KB, free: 4.1 GB)
20/03/13 20:58:16 INFO SparkContext: Created broadcast 1 from broadcast at DAGScheduler.scala:1161
20/03/13 20:58:16 INFO DAGScheduler: Submitting 4 missing tasks from ShuffleMapStage 0 (MapPartitionsRDD[10] at parquet at NativeMethodAccessorImpl.java:0) (first 15 tasks are for partitions Vector(0, 1, 2, 3))
20/03/13 20:58:16 INFO TaskSchedulerImpl: Adding task set 0.0 with 4 tasks
20/03/13 20:58:16 INFO DAGScheduler: Submitting ShuffleMapStage 1 (MapPartitionsRDD[15] at parquet at NativeMethodAccessorImpl.java:0), which has no missing parents
20/03/13 20:58:16 INFO MemoryStore: Block broadcast_2 stored as values in memory (estimated size 12.3 KB, free 4.1 GB)
20/03/13 20:58:16 INFO MemoryStore: Block broadcast_2_piece0 stored as bytes in memory (estimated size 6.8 KB, free 4.1 GB)
20/03/13 20:58:16 INFO BlockManagerInfo: Added broadcast_2_piece0 in memory on instance-2.c.mozaggregator2bq.internal:39195 (size: 6.8 KB, free: 4.1 GB)
20/03/13 20:58:16 INFO SparkContext: Created broadcast 2 from broadcast at DAGScheduler.scala:1161
20/03/13 20:58:16 INFO DAGScheduler: Submitting 4 missing tasks from ShuffleMapStage 1 (MapPartitionsRDD[15] at parquet at NativeMethodAccessorImpl.java:0) (first 15 tasks are for partitions Vector(0, 1, 2, 3))
20/03/13 20:58:16 INFO TaskSchedulerImpl: Adding task set 1.0 with 4 tasks
20/03/13 20:58:16 INFO TaskSetManager: Starting task 0.0 in stage 0.0 (TID 0, localhost, executor driver, partition 0, PROCESS_LOCAL, 8282 bytes)
20/03/13 20:58:16 INFO TaskSetManager: Starting task 1.0 in stage 0.0 (TID 1, localhost, executor driver, partition 1, PROCESS_LOCAL, 8282 bytes)
20/03/13 20:58:16 INFO TaskSetManager: Starting task 2.0 in stage 0.0 (TID 2, localhost, executor driver, partition 2, PROCESS_LOCAL, 8389 bytes)
20/03/13 20:58:16 INFO TaskSetManager: Starting task 3.0 in stage 0.0 (TID 3, localhost, executor driver, partition 3, PROCESS_LOCAL, 8603 bytes)
20/03/13 20:58:16 INFO Executor: Running task 0.0 in stage 0.0 (TID 0)
20/03/13 20:58:16 INFO Executor: Running task 1.0 in stage 0.0 (TID 1)
20/03/13 20:58:16 INFO Executor: Running task 2.0 in stage 0.0 (TID 2)
20/03/13 20:58:16 INFO Executor: Running task 3.0 in stage 0.0 (TID 3)
20/03/13 20:58:16 INFO CodeGenerator: Code generated in 12.365019 ms
```

Spark has come online and is ready to start processing data. It starts to read data from the input path.

```bash
20/03/13 20:58:16 INFO FileScanRDD: Reading File path: file:///home/amiyaguchi/mozaggregator2bq/data/build_id/20160919/497380.dat.gz, range: 0-1039196, partition values: [empty row]
20/03/13 20:58:16 INFO FileScanRDD: Reading File path: file:///home/amiyaguchi/mozaggregator2bq/data/build_id/20160919/497378.dat.gz, range: 0-7237434, partition values: [empty row]
20/03/13 20:58:16 INFO FileScanRDD: Reading File path: file:///home/amiyaguchi/mozaggregator2bq/data/build_id/20160919/497379.dat.gz, range: 0-17387701, partition values: [empty row]
20/03/13 20:58:16 INFO FileScanRDD: Reading File path: file:///home/amiyaguchi/mozaggregator2bq/data/build_id/20160919/497382.dat.gz, range: 0-7579783, partition values: [empty row]
20/03/13 20:58:16 INFO CodeGenerator: Code generated in 15.341377 ms
20/03/13 20:58:16 INFO CodeGenerator: Code generated in 12.353628 ms
20/03/13 20:58:16 INFO CodeGenerator: Code generated in 12.260849 ms
20/03/13 20:58:16 INFO CodecPool: Got brand-new decompressor [.gz]
20/03/13 20:58:16 INFO CodecPool: Got brand-new decompressor [.gz]
20/03/13 20:58:16 INFO CodecPool: Got brand-new decompressor [.gz]
20/03/13 20:58:16 INFO CodecPool: Got brand-new decompressor [.gz]
20/03/13 20:58:18 INFO FileScanRDD: Reading File path: file:///home/amiyaguchi/mozaggregator2bq/data/build_id/20160919/497381.dat.gz, range: 0-51518, partition values: [empty row]
20/03/13 20:58:18 INFO CodecPool: Got brand-new decompressor [.gz]
20/03/13 20:58:18 INFO FileScanRDD: Reading File path: file:///home/amiyaguchi/mozaggregator2bq/data/build_id/20160919/497384.dat.gz, range: 0-30624, partition values: [empty row]
20/03/13 20:58:18 INFO CodecPool: Got brand-new decompressor [.gz]
20/03/13 20:58:18 INFO FileScanRDD: Reading File path: file:///home/amiyaguchi/mozaggregator2bq/data/build_id/20160919/497383.dat.gz, range: 0-28758, partition values: [empty row]
20/03/13 20:58:18 INFO CodecPool: Got brand-new decompressor [.gz]
20/03/13 20:58:18 INFO PythonUDFRunner: Times: total = 2270, boot = 351, init = 371, finish = 1548
20/03/13 20:58:18 INFO Executor: Finished task 3.0 in stage 0.0 (TID 3). 2615 bytes result sent to driver
20/03/13 20:58:18 INFO TaskSetManager: Starting task 0.0 in stage 1.0 (TID 4, localhost, executor driver, partition 0, PROCESS_LOCAL, 7957 bytes)
20/03/13 20:58:18 INFO Executor: Running task 0.0 in stage 1.0 (TID 4)
20/03/13 20:58:18 INFO TaskSetManager: Finished task 3.0 in stage 0.0 (TID 3) in 2641 ms on localhost (executor driver) (1/4)
20/03/13 20:58:18 INFO PythonAccumulatorV2: Connected to AccumulatorServer at host: 127.0.0.1 port: 57721
20/03/13 20:58:18 INFO CodeGenerator: Code generated in 25.070289 ms
20/03/13 20:58:18 INFO PythonRunner: Times: total = 52, boot = -206, init = 257, finish = 1
20/03/13 20:58:18 INFO Executor: Finished task 0.0 in stage 1.0 (TID 4). 2109 bytes result sent to driver
20/03/13 20:58:19 INFO TaskSetManager: Starting task 1.0 in stage 1.0 (TID 5, localhost, executor driver, partition 1, PROCESS_LOCAL, 7958 bytes)
20/03/13 20:58:19 INFO Executor: Running task 1.0 in stage 1.0 (TID 5)
20/03/13 20:58:19 INFO TaskSetManager: Finished task 0.0 in stage 1.0 (TID 4) in 221 ms on localhost (executor driver) (1/4)
20/03/13 20:58:19 INFO PythonRunner: Times: total = 45, boot = -134, init = 179, finish = 0
20/03/13 20:58:19 INFO Executor: Finished task 1.0 in stage 1.0 (TID 5). 2109 bytes result sent to driver
20/03/13 20:58:19 INFO TaskSetManager: Starting task 2.0 in stage 1.0 (TID 6, localhost, executor driver, partition 2, PROCESS_LOCAL, 7961 bytes)
20/03/13 20:58:19 INFO Executor: Running task 2.0 in stage 1.0 (TID 6)
20/03/13 20:58:19 INFO TaskSetManager: Finished task 1.0 in stage 1.0 (TID 5) in 146 ms on localhost (executor driver) (2/4)
20/03/13 20:58:19 INFO PythonRunner: Times: total = 76, boot = -92, init = 168, finish = 0
20/03/13 20:58:19 INFO Executor: Finished task 2.0 in stage 1.0 (TID 6). 2109 bytes result sent to driver
20/03/13 20:58:19 INFO TaskSetManager: Starting task 3.0 in stage 1.0 (TID 7, localhost, executor driver, partition 3, PROCESS_LOCAL, 7960 bytes)
20/03/13 20:58:19 INFO Executor: Running task 3.0 in stage 1.0 (TID 7)
20/03/13 20:58:19 INFO TaskSetManager: Finished task 2.0 in stage 1.0 (TID 6) in 133 ms on localhost (executor driver) (3/4)
20/03/13 20:58:19 INFO PythonRunner: Times: total = 86, boot = -50, init = 135, finish = 1
20/03/13 20:58:19 INFO Executor: Finished task 3.0 in stage 1.0 (TID 7). 2109 bytes result sent to driver
20/03/13 20:58:19 INFO TaskSetManager: Finished task 3.0 in stage 1.0 (TID 7) in 128 ms on localhost (executor driver) (4/4)
20/03/13 20:58:19 INFO DAGScheduler: ShuffleMapStage 1 (parquet at NativeMethodAccessorImpl.java:0) finished in 3.262 s
20/03/13 20:58:21 INFO PythonUDFRunner: Times: total = 5492, boot = 355, init = 333, finish = 4804
20/03/13 20:58:20 INFO FileScanRDD: Reading File path: file:///home/amiyaguchi/mozaggregator2bq/data/build_id/20160919/497377.dat.gz, range: 0-5384939, partition values: [empty row]
20/03/13 20:58:20 INFO PythonUDFRunner: Times: total = 4072, boot = 366, init = 298, finish = 3408
20/03/13 20:58:19 INFO TaskSchedulerImpl: Removed TaskSet 1.0, whose tasks have all completed, from pool
```

The data is transformed. First the table of contents is used to map the raw text
dumps of the tables back to their table names. Then the text RDD is transformed
into a strongly typed data structure.

```bash
20/03/13 20:58:45 INFO CodecPool: Got brand-new decompressor [.gz]
20/03/13 20:58:45 INFO DAGScheduler: looking for newly runnable stages
20/03/13 20:58:45 INFO DAGScheduler: running: Set(ShuffleMapStage 0)
20/03/13 20:58:45 INFO DAGScheduler: waiting: Set(ShuffleMapStage 2, ResultStage 3)
20/03/13 20:58:45 INFO DAGScheduler: failed: Set()
20/03/13 20:58:45 INFO Executor: Finished task 1.0 in stage 0.0 (TID 1). 2572 bytes result sent to driver
20/03/13 20:58:45 INFO TaskSetManager: Finished task 1.0 in stage 0.0 (TID 1) in 29098 ms on localhost (executor driver) (2/4)
20/03/13 20:58:45 INFO Executor: Finished task 0.0 in stage 0.0 (TID 0). 2572 bytes result sent to driver
20/03/13 20:58:45 INFO TaskSetManager: Finished task 0.0 in stage 0.0 (TID 0) in 29124 ms on localhost (executor driver) (3/4)
^[[A20/03/13 20:58:46 INFO PythonUDFRunner: Times: total = 29889, boot = 369, init = 364, finish = 29156
20/03/13 20:58:46 INFO Executor: Finished task 2.0 in stage 0.0 (TID 2). 2572 bytes result sent to driver
20/03/13 20:58:46 INFO TaskSetManager: Finished task 2.0 in stage 0.0 (TID 2) in 30106 ms on localhost (executor driver) (4/4)
20/03/13 20:58:46 INFO TaskSchedulerImpl: Removed TaskSet 0.0, whose tasks have all completed, from pool
20/03/13 20:58:46 INFO DAGScheduler: ShuffleMapStage 0 (parquet at NativeMethodAccessorImpl.java:0) finished in 30.179 s
20/03/13 20:58:46 INFO DAGScheduler: looking for newly runnable stages
20/03/13 20:58:46 INFO DAGScheduler: running: Set()
20/03/13 20:58:46 INFO DAGScheduler: waiting: Set(ShuffleMapStage 2, ResultStage 3)
20/03/13 20:58:46 INFO DAGScheduler: failed: Set()
20/03/13 20:58:46 INFO DAGScheduler: Submitting ShuffleMapStage 2 (MapPartitionsRDD[21] at parquet at NativeMethodAccessorImpl.java:0), which has no missing parents
20/03/13 20:58:46 INFO MemoryStore: Block broadcast_3 stored as values in memory (estimated size 38.5 KB, free 4.1 GB)
20/03/13 20:58:46 INFO MemoryStore: Block broadcast_3_piece0 stored as bytes in memory (estimated size 17.7 KB, free 4.1 GB)
20/03/13 20:58:46 INFO BlockManagerInfo: Added broadcast_3_piece0 in memory on instance-2.c.mozaggregator2bq.internal:39195 (size: 17.7 KB, free: 4.1 GB)
20/03/13 20:58:46 INFO SparkContext: Created broadcast 3 from broadcast at DAGScheduler.scala:1161
20/03/13 20:58:46 INFO DAGScheduler: Submitting 16 missing tasks from ShuffleMapStage 2 (MapPartitionsRDD[21] at parquet at NativeMethodAccessorImpl.java:0) (first 15 tasks are for partitions Vector(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14))
20/03/13 20:58:46 INFO TaskSchedulerImpl: Adding task set 2.0 with 16 tasks
20/03/13 20:58:46 INFO TaskSetManager: Starting task 0.0 in stage 2.0 (TID 8, localhost, executor driver, partition 0, PROCESS_LOCAL, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Starting task 1.0 in stage 2.0 (TID 9, localhost, executor driver, partition 1, PROCESS_LOCAL, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Starting task 5.0 in stage 2.0 (TID 10, localhost, executor driver, partition 5, PROCESS_LOCAL, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Starting task 6.0 in stage 2.0 (TID 11, localhost, executor driver, partition 6, PROCESS_LOCAL, 8084 bytes)
20/03/13 20:58:46 INFO Executor: Running task 0.0 in stage 2.0 (TID 8)
20/03/13 20:58:46 INFO Executor: Running task 1.0 in stage 2.0 (TID 9)
20/03/13 20:58:46 INFO Executor: Running task 5.0 in stage 2.0 (TID 10)
20/03/13 20:58:46 INFO Executor: Running task 6.0 in stage 2.0 (TID 11)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 5 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 7 ms
20/03/13 20:58:46 INFO CodeGenerator: Code generated in 16.797337 ms
20/03/13 20:58:46 INFO CodeGenerator: Code generated in 9.624372 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO CodeGenerator: Code generated in 9.413347 ms
20/03/13 20:58:46 INFO CodeGenerator: Code generated in 19.362442 ms
20/03/13 20:58:46 INFO CodeGenerator: Code generated in 32.077425 ms
20/03/13 20:58:46 INFO Executor: Finished task 6.0 in stage 2.0 (TID 11). 3837 bytes result sent to driver
20/03/13 20:58:46 INFO Executor: Finished task 0.0 in stage 2.0 (TID 8). 3837 bytes result sent to driver
20/03/13 20:58:46 INFO TaskSetManager: Starting task 11.0 in stage 2.0 (TID 12, localhost, executor driver, partition 11, PROCESS_LOCAL, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Starting task 12.0 in stage 2.0 (TID 13, localhost, executor driver, partition 12, PROCESS_LOCAL, 8084 bytes)
20/03/13 20:58:46 INFO Executor: Finished task 5.0 in stage 2.0 (TID 10). 3880 bytes result sent to driver
20/03/13 20:58:46 INFO Executor: Running task 11.0 in stage 2.0 (TID 12)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 6.0 in stage 2.0 (TID 11) in 188 ms on localhost (executor driver) (1/16)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 0.0 in stage 2.0 (TID 8) in 192 ms on localhost (executor driver) (2/16)
20/03/13 20:58:46 INFO TaskSetManager: Starting task 13.0 in stage 2.0 (TID 14, localhost, executor driver, partition 13, PROCESS_LOCAL, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 5.0 in stage 2.0 (TID 10) in 190 ms on localhost (executor driver) (3/16)
20/03/13 20:58:46 INFO Executor: Finished task 1.0 in stage 2.0 (TID 9). 3880 bytes result sent to driver
20/03/13 20:58:46 INFO TaskSetManager: Starting task 15.0 in stage 2.0 (TID 15, localhost, executor driver, partition 15, PROCESS_LOCAL, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 1.0 in stage 2.0 (TID 9) in 192 ms on localhost (executor driver) (4/16)
20/03/13 20:58:46 INFO Executor: Running task 15.0 in stage 2.0 (TID 15)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO Executor: Running task 13.0 in stage 2.0 (TID 14)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO Executor: Running task 12.0 in stage 2.0 (TID 13)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 0 non-empty blocks including 0 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO Executor: Finished task 13.0 in stage 2.0 (TID 14). 3880 bytes result sent to driver
20/03/13 20:58:46 INFO Executor: Finished task 15.0 in stage 2.0 (TID 15). 3837 bytes result sent to driver
20/03/13 20:58:46 INFO Executor: Finished task 12.0 in stage 2.0 (TID 13). 3837 bytes result sent to driver
20/03/13 20:58:46 INFO TaskSetManager: Starting task 2.0 in stage 2.0 (TID 16, localhost, executor driver, partition 2, ANY, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Starting task 3.0 in stage 2.0 (TID 17, localhost, executor driver, partition 3, ANY, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Starting task 4.0 in stage 2.0 (TID 18, localhost, executor driver, partition 4, ANY, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 13.0 in stage 2.0 (TID 14) in 41 ms on localhost (executor driver) (5/16)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 15.0 in stage 2.0 (TID 15) in 40 ms on localhost (executor driver) (6/16)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 12.0 in stage 2.0 (TID 13) in 44 ms on localhost (executor driver) (7/16)
20/03/13 20:58:46 INFO Executor: Running task 2.0 in stage 2.0 (TID 16)
20/03/13 20:58:46 INFO Executor: Finished task 11.0 in stage 2.0 (TID 12). 3837 bytes result sent to driver
20/03/13 20:58:46 INFO Executor: Running task 4.0 in stage 2.0 (TID 18)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO TaskSetManager: Starting task 7.0 in stage 2.0 (TID 19, localhost, executor driver, partition 7, ANY, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 11.0 in stage 2.0 (TID 12) in 57 ms on localhost (executor driver) (8/16)
20/03/13 20:58:46 INFO Executor: Running task 7.0 in stage 2.0 (TID 19)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO Executor: Running task 3.0 in stage 2.0 (TID 17)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO Executor: Finished task 7.0 in stage 2.0 (TID 19). 3966 bytes result sent to driver
20/03/13 20:58:46 INFO TaskSetManager: Starting task 8.0 in stage 2.0 (TID 20, localhost, executor driver, partition 8, ANY, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 7.0 in stage 2.0 (TID 19) in 302 ms on localhost (executor driver) (9/16)
20/03/13 20:58:46 INFO Executor: Running task 8.0 in stage 2.0 (TID 20)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:46 INFO Executor: Finished task 2.0 in stage 2.0 (TID 16). 3966 bytes result sent to driver
20/03/13 20:58:46 INFO TaskSetManager: Starting task 9.0 in stage 2.0 (TID 21, localhost, executor driver, partition 9, ANY, 8084 bytes)
20/03/13 20:58:46 INFO TaskSetManager: Finished task 2.0 in stage 2.0 (TID 16) in 438 ms on localhost (executor driver) (10/16)
20/03/13 20:58:46 INFO Executor: Running task 9.0 in stage 2.0 (TID 21)
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:46 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:47 INFO BlockManagerInfo: Removed broadcast_2_piece0 on instance-2.c.mozaggregator2bq.internal:39195 in memory (size: 6.8 KB, free: 4.1 GB)
20/03/13 20:58:47 INFO BlockManagerInfo: Removed broadcast_1_piece0 on instance-2.c.mozaggregator2bq.internal:39195 in memory (size: 10.5 KB, free: 4.1 GB)
20/03/13 20:58:48 INFO Executor: Finished task 4.0 in stage 2.0 (TID 18). 4009 bytes result sent to driver
20/03/13 20:58:48 INFO TaskSetManager: Starting task 10.0 in stage 2.0 (TID 22, localhost, executor driver, partition 10, ANY, 8084 bytes)
20/03/13 20:58:48 INFO TaskSetManager: Finished task 4.0 in stage 2.0 (TID 18) in 1475 ms on localhost (executor driver) (11/16)
20/03/13 20:58:48 INFO Executor: Running task 10.0 in stage 2.0 (TID 22)
20/03/13 20:58:48 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:48 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:48 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:48 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:50 INFO Executor: Finished task 8.0 in stage 2.0 (TID 20). 4009 bytes result sent to driver
20/03/13 20:58:50 INFO TaskSetManager: Starting task 14.0 in stage 2.0 (TID 23, localhost, executor driver, partition 14, ANY, 8084 bytes)
20/03/13 20:58:50 INFO TaskSetManager: Finished task 8.0 in stage 2.0 (TID 20) in 3184 ms on localhost (executor driver) (12/16)
20/03/13 20:58:50 INFO Executor: Running task 14.0 in stage 2.0 (TID 23)
20/03/13 20:58:50 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:50 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
20/03/13 20:58:50 INFO ShuffleBlockFetcherIterator: Getting 1 non-empty blocks including 1 local blocks and 0 remote blocks
20/03/13 20:58:50 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 0 ms
20/03/13 20:58:50 INFO Executor: Finished task 14.0 in stage 2.0 (TID 23). 4009 bytes result sent to driver
20/03/13 20:58:50 INFO TaskSetManager: Finished task 14.0 in stage 2.0 (TID 23) in 109 ms on localhost (executor driver) (13/16)
20/03/13 20:58:50 INFO Executor: Finished task 3.0 in stage 2.0 (TID 17). 4009 bytes result sent to driver
20/03/13 20:58:50 INFO TaskSetManager: Finished task 3.0 in stage 2.0 (TID 17) in 3710 ms on localhost (executor driver) (14/16)
20/03/13 20:58:50 INFO Executor: Finished task 9.0 in stage 2.0 (TID 21). 4009 bytes result sent to driver
20/03/13 20:58:50 INFO TaskSetManager: Finished task 9.0 in stage 2.0 (TID 21) in 3575 ms on localhost (executor driver) (15/16)
20/03/13 20:58:52 INFO Executor: Finished task 10.0 in stage 2.0 (TID 22). 4009 bytes result sent to driver
20/03/13 20:58:52 INFO TaskSetManager: Finished task 10.0 in stage 2.0 (TID 22) in 4537 ms on localhost (executor driver) (16/16)
20/03/13 20:58:52 INFO TaskSchedulerImpl: Removed TaskSet 2.0, whose tasks have all completed, from pool
20/03/13 20:58:52 INFO DAGScheduler: ShuffleMapStage 2 (parquet at NativeMethodAccessorImpl.java:0) finished in 6.271 s
20/03/13 20:58:52 INFO DAGScheduler: looking for newly runnable stages
20/03/13 20:58:52 INFO DAGScheduler: running: Set()
20/03/13 20:58:52 INFO DAGScheduler: waiting: Set(ResultStage 3)
20/03/13 20:58:52 INFO DAGScheduler: failed: Set()
20/03/13 20:58:52 INFO DAGScheduler: Submitting ResultStage 3 (ShuffledRowRDD[22] at parquet at NativeMethodAccessorImpl.java:0), which has no missing parents
20/03/13 20:58:52 INFO MemoryStore: Block broadcast_4 stored as values in memory (estimated size 144.6 KB, free 4.1 GB)
20/03/13 20:58:52 INFO MemoryStore: Block broadcast_4_piece0 stored as bytes in memory (estimated size 51.1 KB, free 4.1 GB)
20/03/13 20:58:52 INFO BlockManagerInfo: Added broadcast_4_piece0 in memory on instance-2.c.mozaggregator2bq.internal:39195 (size: 51.1 KB, free: 4.1 GB)
20/03/13 20:58:52 INFO SparkContext: Created broadcast 4 from broadcast at DAGScheduler.scala:1161
20/03/13 20:58:52 INFO DAGScheduler: Submitting 1 missing tasks from ResultStage 3 (ShuffledRowRDD[22] at parquet at NativeMethodAccessorImpl.java:0) (first 15 tasks are for partitions Vector(0))
20/03/13 20:58:52 INFO TaskSchedulerImpl: Adding task set 3.0 with 1 tasks
20/03/13 20:58:52 INFO TaskSetManager: Starting task 0.0 in stage 3.0 (TID 24, localhost, executor driver, partition 0, ANY, 7767 bytes)
20/03/13 20:58:52 INFO Executor: Running task 0.0 in stage 3.0 (TID 24)
20/03/13 20:58:52 INFO ShuffleBlockFetcherIterator: Getting 8 non-empty blocks including 8 local blocks and 0 remote blocks
20/03/13 20:58:52 INFO ShuffleBlockFetcherIterator: Started 0 remote fetches in 1 ms
```

Now Spark is ready to write to disk. This will get formatted into Parquet, a
columnar, binary file format. The schema is generated by Catalyst, Spark's query
optimizer.

```bash
20/03/13 20:58:52 INFO FileOutputCommitter: File Output Committer Algorithm version is 1
20/03/13 20:58:52 INFO SQLHadoopMapReduceCommitProtocol: Using user defined output committer class org.apache.parquet.hadoop.ParquetOutputCommitter
20/03/13 20:58:52 INFO FileOutputCommitter: File Output Committer Algorithm version is 1
20/03/13 20:58:52 INFO SQLHadoopMapReduceCommitProtocol: Using output committer class org.apache.parquet.hadoop.ParquetOutputCommitter
20/03/13 20:58:52 INFO CodecConfig: Compression: SNAPPY
20/03/13 20:58:52 INFO CodecConfig: Compression: SNAPPY
20/03/13 20:58:52 INFO ParquetOutputFormat: Parquet block size to 134217728
20/03/13 20:58:52 INFO ParquetOutputFormat: Parquet page size to 1048576
20/03/13 20:58:52 INFO ParquetOutputFormat: Parquet dictionary page size to 1048576
20/03/13 20:58:52 INFO ParquetOutputFormat: Dictionary is on
20/03/13 20:58:52 INFO ParquetOutputFormat: Validation is off
20/03/13 20:58:52 INFO ParquetOutputFormat: Writer version is: PARQUET_1_0
20/03/13 20:58:52 INFO ParquetOutputFormat: Maximum row group padding size is 8388608 bytes
20/03/13 20:58:52 INFO ParquetOutputFormat: Page size checking is: estimated
20/03/13 20:58:52 INFO ParquetOutputFormat: Min row count for page size check is: 100
20/03/13 20:58:52 INFO ParquetOutputFormat: Max row count for page size check is: 10000
20/03/13 20:58:52 INFO ParquetWriteSupport: Initialized Parquet WriteSupport with Catalyst schema:
{
  "type" : "struct",
  "fields" : [ {
    "name" : "ingest_date",
    "type" : "date",
    "nullable" : false,
    "metadata" : { }
  }, {
    "name" : "aggregate_type",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "ds_nodash",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "channel",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "version",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "os",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "child",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "label",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "metric",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "osVersion",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "application",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "architecture",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  }, {
    "name" : "aggregate",
    "type" : "string",
    "nullable" : true,
    "metadata" : { }
  } ]
}
and corresponding Parquet message type:
message spark_schema {
  required int32 ingest_date (DATE);
  optional binary aggregate_type (UTF8);
  optional binary ds_nodash (UTF8);
  optional binary channel (UTF8);
  optional binary version (UTF8);
  optional binary os (UTF8);
  optional binary child (UTF8);
  optional binary label (UTF8);
  optional binary metric (UTF8);
  optional binary osVersion (UTF8);
  optional binary application (UTF8);
  optional binary architecture (UTF8);
  optional binary aggregate (UTF8);
}
```

The final schema breaks out the two original columns (`dimensions` and `aggregates`) into more granular columns.
This also adds metadata such as the ingestion date (when the table was dumped from `postgresql`) and whether this is a build or submission aggregate.

```bash
20/03/13 20:58:52 INFO CodecPool: Got brand-new compressor [.snappy]
20/03/13 20:58:56 INFO InternalParquetRecordWriter: Flushing mem columnStore to file. allocated memory: 43258712
20/03/13 20:58:56 INFO FileOutputCommitter: Saved output of task 'attempt_20200313205816_0003_m_000000_24' to file:/home/amiyaguchi/mozaggregator2bq/data/parquet/build_id/20160919/_temporary/0/task_20200313205816_0003_m_000000
20/03/13 20:58:56 INFO SparkHadoopMapRedUtil: attempt_20200313205816_0003_m_000000_24: Committed
20/03/13 20:58:56 INFO Executor: Finished task 0.0 in stage 3.0 (TID 24). 2377 bytes result sent to driver
20/03/13 20:58:56 INFO TaskSetManager: Finished task 0.0 in stage 3.0 (TID 24) in 3713 ms on localhost (executor driver) (1/1)
20/03/13 20:58:56 INFO TaskSchedulerImpl: Removed TaskSet 3.0, whose tasks have all completed, from pool
20/03/13 20:58:56 INFO DAGScheduler: ResultStage 3 (parquet at NativeMethodAccessorImpl.java:0) finished in 3.739 s
20/03/13 20:58:56 INFO DAGScheduler: Job 0 finished: parquet at NativeMethodAccessorImpl.java:0, took 40.247661 s
20/03/13 20:58:56 INFO FileFormatWriter: Write Job 018cdc48-1967-49ee-a4ab-d80006c0bb71 committed.
20/03/13 20:58:56 INFO FileFormatWriter: Finished processing stats for write job 018cdc48-1967-49ee-a4ab-d80006c0bb71.
20/03/13 20:58:56 INFO SparkContext: Invoking stop() from shutdown hook
20/03/13 20:58:56 INFO SparkUI: Stopped Spark web UI at http://instance-2.c.mozaggregator2bq.internal:4040
20/03/13 20:58:56 INFO MapOutputTrackerMasterEndpoint: MapOutputTrackerMasterEndpoint stopped!
20/03/13 20:58:56 INFO MemoryStore: MemoryStore cleared
20/03/13 20:58:56 INFO BlockManager: BlockManager stopped
20/03/13 20:58:56 INFO BlockManagerMaster: BlockManagerMaster stopped
20/03/13 20:58:56 INFO OutputCommitCoordinator$OutputCommitCoordinatorEndpoint: OutputCommitCoordinator stopped!
20/03/13 20:58:56 INFO SparkContext: Successfully stopped SparkContext
20/03/13 20:58:56 INFO ShutdownHookManager: Shutdown hook called
20/03/13 20:58:56 INFO ShutdownHookManager: Deleting directory /tmp/spark-6bd9fb0d-60b2-4e7e-afae-9bb07686940c
20/03/13 20:58:56 INFO ShutdownHookManager: Deleting directory /tmp/spark-ef970312-9f5c-4028-a6af-a927b47652ef/pyspark-86583580-f823-4f59-8ae3-ff58f8427906
20/03/13 20:58:56 INFO ShutdownHookManager: Deleting directory /tmp/spark-ef970312-9f5c-4028-a6af-a927b47652ef
```

The Spark processing completes, leaving behind a parquet file.
This file gets uploaded to a Google Cloud Storage bucket for later ingestion into BigQuery.

```bash
+ gsutil rsync -d -r data/parquet/build_id/20160919/ gs://mozaggregator2bq/data/build_id/20160919/

WARNING: gsutil rsync uses hashes when modification time is not available at
both the source and destination. Your crcmod installation isn't using the
module's C extension, so checksumming will run very slowly. If this is your
first rsync since updating gsutil, this rsync can take significantly longer than
usual. For help installing the extension, please see "gsutil help crcmod".
```

As a side-note, I haven't figured out how to install `crcmod` for the included
`python2` distribution that comes packaged in the CentOS 8 image on the Google
Compute Engine VM. By default, `python2` is no longer installed on CentOS, but
`gsutil` is still using `python2`.

```bash
Building synchronization state...
Starting synchronization...
Copying file://data/parquet/build_id/20160919/._SUCCESS.crc [Content-Type=application/octet-stream]...
Copying file://data/parquet/build_id/20160919/.part-00000-77193b9f-ba77-41cd-9589-462b65da9287-c000.snappy.parquet.crc [Content-Type=application/octet-stream]...
Copying file://data/parquet/build_id/20160919/_SUCCESS [Content-Type=application/octet-stream]...
Copying file://data/parquet/build_id/20160919/part-00000-77193b9f-ba77-41cd-9589-462b65da9287-c000.snappy.parquet [Content-Type=application/octet-stream]...
\ [4 files][ 39.2 MiB/ 39.2 MiB]
Operation completed over 4 objects/39.2 MiB.
```

The upload completes, leaving us to process the next steps.

```bash
+ local table=aggregates.build_id_aggregates
+ false
+ echo 'skipping bq load for aggregates.build_id_aggregates'
+ return
skipping bq load for aggregates.build_id_aggregates

real    1m15.367s
user    1m4.076s
sys     0m2.912s
```

Overall, 1:15 is not a bad time to process a single day. It should only take a
day or two to process all four years of aggregates from the old database, before
it is decommissioned for good.
