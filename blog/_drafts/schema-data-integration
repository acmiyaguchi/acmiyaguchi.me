---
layout: post
title: Bringing a Continuous Schema Integration System Online
date:   2018-06-08 4:50:00 -0700
category: Engineering
tags:
    - System
    - Schema
    - Data Ingestion
    - Continuous Integration
---

The data lake has become a popular model of storing analytical data.
Datasets are stored as files or documents in a columnar format to take advantage of data parallelism.
Data processing engines have grown to accomodate the demand for this object model of data.
Projects like Spark, Hive, and Presto understand the columnar data model and provide a flexible programming interface that build on ideas from database systems.
The health of a data lake is then dependent on the quality of the data it contains.

At Mozilla, performance and usage measurements from Firefox provide the foundation necessary for engineering decisions.
Metrics from browser telemetry improves confidence in changes such as multi-process engine capabilities and multi-language integration.
Because of the modular nature of the engine, the measurement probes form a natural structure.
These probes are flexible, collecting information on things like the count of crashes or the distribution of latencies.
Data doesn't have inherent value, it is part of a larger process.
Experiments are one such process, where the analysis is dependent on reliable data collection.
This data-driven mode of execution also relies on the documented structure of the data.

Schemas define the information contained within a document.
A schema is composed of many rules that are used to determine validity.
If a document does not conform to a schema, it is considered to be invalid.
The schema of a large system can be complex, but documenting the structure can identify areas of improvement and necessary monitoring.

The best way to enforce this quality is to monitor at the sources.
The ingestion endpoints apply schemas to known document types in order to enforce structural qualities.
Telemetry payloads are sent to ingestion in a compressed json document which are unpacked, validated against a schema, and serialized for further processing.
There is a path for deploying new schemas, but ensuring correctness is an uphill battle.
We can take samples from the source data and test them against development

## An integration system

## Designing the core

## Building from the edges

## Completing the feedback loop

## Retrospective

## Future
