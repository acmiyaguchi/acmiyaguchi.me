---
layout: post
title: Semantic versioning, it works
date:   2018-06-08 4:50:00 -0700
category: Engineering
tags:
    - Open Source
    - Libraries
    - Software Release
---

Semantic versioning makes software maintainable by a community.
Libraries of code are meant to be used and read.
Open source libraries are even more so, but then they become a common.
The source of responsibility is then on the community in order to keep things stable.

# A frustrating story

I was building a service for running JSON documents through a JSON schema.
This implemented a validation feedback loop for developers interested in working on the Firefox data platform.
I also sampled documents to run through this service to check the health of the schemas.
A reviewer noticed that one of the more important documents by volume was showing 100% error.
This was a weird thing, because it seemed that all my libraries were up to date.

Fortunately, the tool I had built was for diagnosing this exact problem.
I used a comparison tool to find the point in history where this document was introduced.
I narrowed down the revision to a change that I had made earlier that enforced a structure using a more advanced feature.
The additionalProperties and patternProperties were used to verify that values in a histogram were being enforced.
In the PR, I was reminded that this was an issue in the underlying rapidjson library that we had been using.
It turns out, this was the same exact problem that we had been seeing!

I filed a bug report with the python binding I was using.
This case was easy because there is a comprehensive tutorial for writing json schemas.
I wrote the test cases and verified that bumping the submodule version worked.
The issue was easy to diagnose and the direction to a fix was tangible, but there are some problems.
The last release of rapidjson was from a year and half ago, with no bug-fixes in sight.
There was an issue and a patch that were both fixed in the time spanned since that release, but no guarantee on the stability of the future changes.
How do you release software that other people depend on?

## The semantics of semantic versioning

The cadence of releases reflects software as a living thing.

Perhaps responsibility for a software roadmap should be given to a maintainer or creator.
The benevolent dictator for life has shown to be a somewhat effective model for some projects and maintainers.

But as an ecosystem evolves around a library, changes and bugs become part of the problem.
A single person can't do everything.
I also don't think comittees solve every problem.
But semantic versioning helps alleviate issues around library compatibility by providing a clear set of understanding.

When the major revision changes, there have been changes to the API that are breaking.
Python 2 and Python 3 is an infamous example, where the transition has been happening for over 10 years.
However, new libraries that do not support python 3 help break the mold, making it difficult to start a new project in the older API.
When the minor revision changes, there have been backwards compatible changes that do not affect any current modules.
This means you can safely upgrade without worrying about breaking the code you've been writing, and you can expect some nice features too.
Finally, the final position is for the number of bugfixes that have been included in the library.

Semantic versioning forms a contract between the software, the developers, and the users.
When there are multiple projects working together, there is a known interoperability in protocols and APIs.
This occurs in open source software, where responsibility is shared between maintainers and contributors.
However, everyone benefits from the software because it is freely available.
Versioning doesn't solve all problems, but it does clearly communicate changes that have been made.

## A happy ending

It turns out, dependencies can be handled further downstream.
Even if there isn't an official release, the behavior and characteristics of the software are enough to make a decision.
However, the cognitive load required because of due dilligence is high.
Maintaining releases on an unofficial schedule requires testing, auditing, and being confident of changes.
This is workable, but it could be better.

This whole situation gave me an opportunity to contribute to a library that has been very useful.
I'm thankful that the library maintainer for python-rapidjson was responsive.
It was a nice feeling to be included as part of a new release that actually fixes real problems.
Maybe releasing software in a consistent way is fundamental for building open source commuinities.
There is a sense of responsibility that comes from making changes that matter, because bug-fixes are for the common good.

Off to build more software.