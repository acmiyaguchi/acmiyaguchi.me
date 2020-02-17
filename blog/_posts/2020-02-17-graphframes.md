---
layout: post
title: Inducing Wikipedia Subgraphs with GraphFrames
date:   2020-02-17 17:00:00 -0800
category: Engineering
tags:
    - spark
    - graphframes
    - wikipedia
---

I've been toying around with building a tool for analyzing news articles through the relationship of [named entities][named-entity] in the text.
A named entity is a real world object that has a proper name (e.g. the Royal Palace of Madrid). 
A good rule of thumb is that if it's significant enough to have a Wikipedia page, then it's likely to be a named entity.
The test subject of my news analysis have been arbitrary articles from the Associated Press (AP).
For the data processing pipeline that I've built, I consider the [AP news article about Jimmy Hoffa][hoffa]. 
With a script to parse the page and [extract the entities][ner], I have a group of entities that we can start drawing relationships from. 
I clean up results [`NLTK`][nlkt] by passing them into the Wikipedia search API to get a list of article ids and titles.

```csv
Id,Label
8687,Detroit
11127,Federal Bureau of Investigation
18995,Martin Scorsese
115009,Kansas City  Kansas
158984,Harvard Law School
255722,Jimmy Hoffa
323246,Goldsmith
334010,International Brotherhood of Teamsters
594156,Mafia
1250883,Church Committee
...
```

I now start to build up a graph, armed with entities referenced in the Jimmy Hoffa article.

I start with the `pages` and `pagelinks` data sets that I extracted from the 2019-08-20 dump of English Wikipedia.
In this dump, there are 5.9 million articles and 490 million links between them.
The pages data set contains information about each article in the database, most importantly the unique id and title.
The pagelinks data set is an adjacency list that represents the hyperlinks between articles.
This forms the basis of building up the graph of relationships between articles in Wikipedia.
I took [some notes][wiki-notes] on extracting the data from the SQL dumps using the [epfl-lts2/sparkwiki](https://github.com/epfl-lts2/sparkwiki) project.

With this, I put together a simple script to generate a [induced subgraph][induced-subgraph].
This will draw an edge between two articles if a hyperlink exists in the `pagelinks` data.
I started with [`graphframes`][graphframes] to search for these relationships, because I already had most of the code lying around.

I enjoy using Spark because I'm familiar with the API and the execution model.
It's also great for manipulating data on a local machine.
Here's a mostly complete fragment demonstrating the use of `graphframes`.

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import broadcast, expr
from graphframes import GraphFrame

articles = spark.read.csv("articles.csv")
pages = spark.read.parquet("data/pages")
pagelinks = spark.read.parquet("data/pagelinks")

graph = GraphFrame(pages, pagelinks.selectExpr("from as src", "dest as dst"))

edgelist = (
    graph.find("(a)-[]->(b)")
    .join(broadcast(ids), on=expr("a.id=article_id"), how="inner")
    .drop("article_id")
    .join(broadcast(ids), on=expr("b.id=article_id"), how="inner")
    .drop("article_id")
    .selectExpr("a.id as src", "b.id as dst")
)

(
    edgelist.selectExpr("src as Source", "dst as Target", "1 as Weight")
    .coalesce(1)
    .write.csv(f"edges", header=True, mode="overwrite")
)
```

![Query plan]({{ "/assets/2020-02-17/query-plan.png" | absolute_url }})

This gets run with a small Powershell script, after the appropriate dependencies are installed (`pip install pyspark`).

```powershell
$filename = "scripts/generate_graph.py"
$env:SPARK_HOME = $(python -c "import pyspark; print(pyspark.__path__[0])")

spark-submit `
    --master 'local[*]' `
    --conf spark.driver.memory=24g `
    --conf spark.sql.shuffle.partitions=32 `
    --packages graphframes:graphframes:0.7.0-spark2.4-s_2.11 `
    $filename @args
```

This job completes in roughly 10 minutes on my desktop.
When run on an `n1-standard-16` machine on [Google Cloud Dataproc][dataproc], this takes closer to 4 minutes.

The result is an edge table that can be imported directly into [Gephi][gephi], a tool for graph analysis and visualization. 

```csv
Source,Target,Weight
158984,17003967,1
19571,8687,1
255722,8687,1
10687798,18995,1
43792007,18995,1
255722,18995,1
...
```

With some minor fiddling, we can compute some nice statistics about the resulting entity graph from the original news article.

![Wikipedia relations for the AP news article]({{ "/assets/2020-02-17/hoffa.png" | absolute_url }})


[hoffa]: https://apnews.com/1673463e5dd7eff87d2dc53e06ec9c24
[named-entity]: https://en.wikipedia.org/wiki/Named_entity
[ner]: https://www.nltk.org/book/ch07.html#sec-ner
[nltk]: https://www.nltk.org/
[wiki-notes]: https://github.com/acmiyaguchi/cs229-f19-wiki-forecast/blob/master/NOTES.md
[induced-subgraph]: https://en.wikipedia.org/wiki/Induced_subgraph
[graphframes]: https://graphframes.github.io/graphframes/docs/_site/user-guide.html#motif-finding
[dataproc]: https://cloud.google.com/dataproc
[gephi]: https://gephi.org/