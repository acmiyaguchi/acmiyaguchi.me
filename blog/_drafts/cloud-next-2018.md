---
layout: post
title:  Thoughts on Google Cloud Next 2018
date:   2018-07-01 20:00:45 -0700
category: Engineering
tags:
    - google cloud
    - conference
    - cloud computing
---

Google Cloud has been a strong contender ever since it entered the public cloud space in 2012.
This year, their [quarterly revenue reached an excess of billion dollars](https://www.cnbc.com/2018/02/01/google-cloud-revenue-passes-1-billion-per-quarter.html).
While they still tail Amazon Web Services and Microsoft Azure in the market, they have years of experience with distributed systems and data center operations.
At Google Cloud Next 2018, I gained a broad overview of the Google Cloud Platform (GCP) and heard from a diverse pool of engineering organizations about their experiences.

# Independence of Compute and State

One of the advantages of being on a cloud platform is that data can now live separately from the computers that process it.
The serverless trend uses this principle to provide services that can scale on demand.
A data system may rely on computing and storage services connected through a virtual network.
Without the tight coupling, it's possible to do things like scaling down compute based on low demand while maintaining a consistent store of data.
The decomposition of the infrastructure components makes it easier to reason about the design of analytic data frameworks.

<style>
 .center {
    display: block;
    margin-left: auto;
    margin-right: auto;
    width: 60%;
}
</style>

<a title="By Kapooht [CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0)], from Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Von_Neumann_Architecture.svg">
<img width="100%" class="center" alt="Von Neumann Architecture" src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Von_Neumann_Architecture.svg/256px-Von_Neumann_Architecture.svg.png"></a>

_**Figure**: Data flow is IO bound in the Von Neumann architecture, from Wikimedia Commons._
{: style="text-align: center"}

Apache Beam, or Cloud Dataflow on GCP, is a unified batch/stream programming model that can run on other popular frameworks like [Spark](http://spark.apache.org/) and [Flink](https://flink.apache.org/).
Dataflow is positioned to be the one-stop shop for moving data between systems.
Moving data can be surprisingly hard because of hard limits on IO.
It's painfully evident when resources are limited, especially on Map-Reduce style workloads where IO can make a huge difference.
Data-heavy algorithms like [association rule learning](https://en.wikipedia.org/wiki/Association_rule_learning) that run in this setting are measured in passes over the data to account for the non-trivial communication costs.

Fortunately, there are ways to squeeze performance out of clusters of commodity computer.
Faster hardware and judicious caching is the typical solution to the [Von Neumann](https://en.wikipedia.org/wiki/Von_Neumann_architecture#Von_Neumann_bottleneck) bottleneck, a situation that occurs when trying to move between program and data memory.
A typical benchmark for measuring performance here is to sort a list of a quadrillion integers.
Sorting a list in a distributed system requires a bit of coordination and fast networks to complete quickly.
Tuning the cluster to take advantage of SSDs and faster networks can reduce workload times significantly.
However, it's also possible to reduce this bottleneck by adding a managed layer just for shuffling data.

An external shuffle service can make smart decisions and utilize hardware to improve this bottleneck across a variety of workloads.
For example, [super-seeding](https://en.wikipedia.org/wiki/Super-seeding) is an algorithm in the BitTorrent protocol that can reduce the time to file distribution.
Super-seed nodes selectively offer files to peers so they can start uploading to the network more quickly.
Efficient network topologies like a [butterfly network](https://en.wikipedia.org/wiki/Butterfly_network) can be applied directly to the nodes implementing a shuffle service to reduce the time of data distribution between compute and data nodes.
The symbiotic relationship of hardware and software is vital for accelerating the typical data warehousing workloads in a modular and cost-effective way.

The Dataflow Shuffle service [claims a 5x improvement](https://cloud.google.com/blog/products/gcp/introducing-cloud-dataflow-shuffle-for-up-to-5x-performance-improvement-in-data-analytic-pipelines) in some typical batching workflows like joins.
The same principles can be used in the streaming mode to make the system [more responsive](https://cloud.google.com/blog/products/data-analytics/introducing-cloud-dataflows-new-streaming-engine
) to autoscaling conditions.
While the [abstraction is not unique](https://spark.apache.org/docs/latest/job-scheduling.html#configuration-and-setup), the Dataflow engines leverage the robust infrastructure and unified programming models to provide a seamless experience.

# Evaluation of a Cloud Platform

One of the draws of going to a conference like Cloud Next was to hear about the challenges of other organizations as they evaluated and migrated their workloads to Google Cloud.
There are two broad models for migrating a system: lifting and shifting, and re-architecting.
Lift and shift is the process of moving a system as-is, relying on equivalent services between providers.
A re-architecture typically uses the patterns of the platform to adapt to the business case.
Like any challenging problem, neither model is necessarily the best and come with tradeoffs to consider.

In the geospatial data space, Planet Labs presented their processing pipeline for how they [scan the Planet Earth in seconds](https://www.youtube.com/watch?v=zlVPBeDoXKQ).
Google also maintains Maps, which shares a considerable overlap with Planet's product.
It turns out that maintaining a constellation of 150 satellites requires a data-heavy operation.
With a catalog of over 7PB and a daily ingest of 6 TB of images, their team phased the infrastructure migration into manageable pieces.
First, they waited three weeks to upload their images into Cloud Storage.
In the background, their metadata database was replicating transactions to a Cloud SQL.
The compute-heavy mosaic and data stitching jobs were also ported to run on the Google Compute Engine.
In the second phase, they containerized all of their services with Kubernetes to take advantage of autoscaling and monitoring.
Overall, it seems like Planet Labs aligns with Google in both their workload and their mission.

<a title="By NASA/JPL-Caltech [Public domain], via Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Thinking_Inside_the_Box,_Launching_Into_Space.png"><img width="100%" class="center" alt="Thinking Inside the Box, Launching Into Space" src="https://upload.wikimedia.org/wikipedia/commons/6/6a/Thinking_Inside_the_Box%2C_Launching_Into_Space.png"></a>

_**Figure**: Cube satellites provide an abundance of raw data, from Wikimedia Commons._
{: style="text-align: center"}

In the mobile advertising space, TapJoy made their [transition from Vertica and on-prem Hadoop to BigQuery and an elastic Hadoop](https://www.youtube.com/watch?v=ZDRPAkqPRHQ).
Both Vertica and BigQuery are column-store databases that understand SQL, but BigQuery is better in all practical aspects.
One interesting practice is that TapJoy maintains a catalog of schemas to describe their data.
Even though BigQuery can infer schemas, schemas can provide useful context and be used to validate incoming data.
In addition to the BigQuery, they migrated to managed Hadoop cluster for their other analytical workloads.
Hadoop as a platform seems to be a prime target for migration because it abstracts the workload from the infrastructure.
Map-Reduce is well suited for generating advertising recommendations to maximize the click-through-rate (CTR) metric.
Hadoop on GCE satisfied their needs and is not as terrifying as it sounds.

Twitter went into detail about how they [chose Google Cloud Platform](https://www.youtube.com/watch?v=4FLFcWgZdo4) for their Hadoop infrastructure.
They had some great insight into the planning and decision making necessary for a 10-year time horizon at a large engineering organization.
The Twitter firehose has unique challenges with 300 PB of data, such as having to establish a public peering relationship for transferring data.
While they evaluated across their entire infrastructure workloads, Hadoop provides an infrastructure agnostic platform for evaluating workloads.

They took a rigorous approach in their evaluation:

* functional tests to see if things would run
* micro-benchmarks for measuring system performance and potential configurations
* macro-benchmarks for establishing performance
* scale testing to get close to production load
* validate with the provider
* iterate and optimize

The benchmarks increased their confidence in the platform, letting them spin up a 10,000 node Presto cluster to run some ad-hoc analysis on a 15 petabyte data-set without issue.
While their migration is still ongoing, they've found that their systematic evaluation has helped with their cloud adoption.

# MiniGo and Heterogeneous Computing

The ability to use clusters of diverse hardware has increased the speed of search dramatically.
MapReduce has proven to be a useful framework for implementing large-scale matrix methods like PageRank.
Other distributed efforts like [Folding@home](https://en.wikipedia.org/wiki/Folding@home)  have had success in harnessing the average PC for simulating protein folding to cure diseases.
While networked computers are one way of increasing parallelism, co-processors like GPUs also significantly accelerate parallel data tasks.
In my last session of Cloud Next, I saw how the ability to harness distributed and hardware parallelism could be used to build a Go AI.

<a title="By Donarreiskoffer [GFDL (http://www.gnu.org/copyleft/fdl.html) or CC-BY-SA-3.0 (http://creativecommons.org/licenses/by-sa/3.0/)], from Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Go_board.jpg"><img width="100%" class="center" alt="Go board" src="https://upload.wikimedia.org/wikipedia/commons/2/2e/Go_board.jpg"></a>

_**Figure**: A Go board, from Wikimedia Commons._
{: style="text-align: center"}


[MiniGo](https://www.youtube.com/watch?v=Qra8Aqxu_fo) reproduces the Alpha Go Zero paper, written and scaled through Tensorflow and Kubernetes.
Once thought impossible to defeat humans in a game of Go, advances in machine learning and [ASIC](https://en.wikipedia.org/wiki/Application-specific_integrated_circuit) have given Go AIs superhuman strength.
To build such a model, a network of computers plays many games against itself to reinforce neural networks predicting the next moves.
The huge search space ([nearly 10^192 positions](https://en.wikipedia.org/wiki/Go_and_mathematics)) is made tractable through a probabilistic tree search and efficient inference hardware.

The right level of abstractions has made this type of artificial intelligence highly practical.
Tensorflow abstracts the network of the model from how it's run -- the software can dynamically assign relevant tasks to the most capable hardware.
The same code also runs on any hardware, whether it be a CPU, GPU, or TPU.
Kubernetes makes it possible to run many of these games in parallel by orchestrating many training sessions in parallel.
This workflow works exceptionally well on Google Cloud because of managed services for both Kubernetes and Tensorflow, as well as access to hardware like TPUs.
In the case of Alpha Go, TPUs can take advantage of the board symmetry to reduce inference time from 30ms to 2ms.

With tens of thousands of games and several weeks later, MiniGo can produce an engine that can beat most (if not all) humans.
It's interesting to see all of the different applications that are possible now that the hardware is becoming a commodity.
The announcement of [3rd generation of TPUs](https://techcrunch.com/2018/05/08/google-announces-a-new-generation-for-its-tpu-machine-learning-hardware/) for learning in the cloud and an [embedded TPU for inference at the edge](https://cloud.google.com/edge-tpu/) shows a likely trend for machine learning and artificial intelligence to increase in everyday life.


# Conclusions

Infrastructure as a service has reached a point of maturity where all of the competing platforms provide roughly the same magnitude of value.
Building the cloud instead of an on-premise data center makes sense for many workloads because of the ability to elastically scale compute and storage resources independently with fast enough materials.
Abstractions at the right level can reduce operational complexity, such as Dataflow for unifying batch and streaming and Kubernetes for container orchestration.
Google Cloud Platform has been showing a great deal of growth and offers a solid line-up of tools for building and maintaining data-intensive systems.
I'm interested in new the changes that platform has in store.