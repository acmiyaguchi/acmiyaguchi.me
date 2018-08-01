---
layout: post
title: Building in a Public Cloud
date:   2018-07-01 20:00:45 -0700
category: Engineering
tags:
    - google cloud
    - conference
    - cloud computing
---

Google Cloud has been growing quickly since it was started in 2012. Earlier this year, they stated revenue exceeding a [billion dollars a quarter](https://www.cnbc.com/2018/02/01/google-cloud-revenue-passes-1-billion-per-quarter.html). While they're tailing Amazon and Azure in the public cloud space, they have plenty of experience with data center operations and operating at scale. At Google Cloud Next, I had the chance to familiarize myself with an overview of the platform and listen to the experiences of other engineering organizations in their transitions.

# Independence of Compute and State

Data

<style>
 .center {
    display: block;
    margin-left: auto;
    margin-right: auto;
    width: 50%;
}
</style>

<a title="By Kapooht [CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0)], from Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Von_Neumann_Architecture.svg">
<img width="75%" class="center" alt="Von Neumann Architecture" src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Von_Neumann_Architecture.svg/256px-Von_Neumann_Architecture.svg.png"></a>

_**Figure**: Data flow is IO bound in the the Von Neumann architecture, from Wikimedia Commons._


Moving data around between systems is difficult because of the limited IO of a single CPU. Faster hardware and judicious caching has been the typical solution to the [Von Neumann](https://en.wikipedia.org/wiki/Von_Neumann_architecture#Von_Neumann_bottleneck) bottleneck, a situation that occurs when trying to move between program and data memory. This issue is painfully clear when resources are limited in data processing frameworks like Hadoop. Naturally, sorting a large list of numbers (say 10^12 bytes of data) has become the standard benchmark for distributed data systems. IO latency from disk and network contribute a non-trivial communication cost to an algorithm that typically runs in time O(n log(n)). For this same reason, data heavy algorithms such as [association rule learning](https://en.wikipedia.org/wiki/Association_rule_learning) are measured in passes over the data.

https://cloud.google.com/blog/big-data/2017/10/separation-of-compute-and-state-in-google-bigquery-and-cloud-dataflow-and-why-it-matters

https://cloud.withgoogle.com/next18/sf/sessions/session/155632
"Advancing Serverless Data Processing in Cloud Dataflow by Separating State Storage from Compute"


Computations like joins are often limited by the network because the operation requires shuffling data between computers such that keys are local to a specific node. Frameworks like Spark and Tensorflow tackle the overhead of moving data by add creating a graph of computation to avoid unnecessary shuffles. When data locality no longer matters, there are some nice applications that can help reduce data processing times.

Apache Beam is a data processing agnostic to batching or streaming. Google Cloud has a managed service called Dataflow, which lays squarely between the messaging queue and data lake. Because it also provides data structures suited to parallel processing across heteroegenous hardware, the Beam also has to deal with shuffles. Here, the seperation of compute and state makes it possible to speed up shuffles without any tuning. Some basic ways of tuning include moving to SSDs. To improve stateful processing, an in-memory triple store can be used to coordinate across a fast network. The 5x speed improvements are nice, and seem to expose themselves in other places.

# Hadoop@Twitter: Evaluation of a Cloud Platform

Twitter has really become engrained as a piece of internet infrastructure that will likely be around for the foreseeable future. Likewise, at an engineering level, they plan 10 years out in advance for their data strategy. Their unique scale and performance means that they need to be rigorous with their systems. One particular slide that I found interesting was the plan for establishing their workload on a new provider.

With an efficient topology and fast networks, compute and state can be scaled indepenently. [Twitter](https://cloud.withgoogle.com/next18/sf/sessions/session/230166) found through their comprehensive benchmarking that data locality doesn't matter on Google Cloud. This makes the platform attractive for building large scale data applications.


* functional tests to see if things would run
* micro-benchmarks for measuring system performance and potential configurations
* macro-benchmarks for establishing performance
* scale testing to get close to production load
* validate with the provider
* iterate and optimize

It's awesome that they were able to bring up a 10,000 node Presto cluster to run some ad-hoc analysis on a 15 petabyte data-set without any serious issues.

# MiniGo and Heterogeneous Computing

One talk I found particularly interesting was one on building MiniGo, an implementation of the Alpha Zero paper. Go was a challenging game for computers to reach competitive levels of skill, but advances in machine learning have made it possible. Neural networks are trained from a blank slate through many games of self-play, made possible by probablistic tree search and efficient hardware for inference. Building a competitive model requires a large number of games, which can be played in parallel.

There are ways of publically sourcing these games. For example, Folding@Home was one of the first efforts of building a distrubuted computing platform for accelerating cancer drug developments through simulations of protein folding. When cost becomes less of a factor, then running on the cloud becomes an attractive place to run these computations.

The right level of abstractions have made this type of artificial intelligence to become highly practical. Tensorflow abstracts the architecture of the neural network from how the computation is done. Since the networks can be represented as a graph of computation, the compute can be optimized to run across all sorts of different hardware. The same operations can be run on CPUs, GPUs, and TPUs, based on the best allocation of resources. Kubernetes makes it possible to run many of these games in parallel by orchestrating many runs of the training models across Google Cloud instances. However, this architecture can be run anywhere because of the open source nature of the tooling. The ubiquity of a public cloud makes computationally difficult tasks like this a matter of cost than techincal feasibility.


# Conclusions

