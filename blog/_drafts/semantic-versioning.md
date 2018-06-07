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

# A murder mystery

As a data engineer, most of the data I've worked with has been in a sane format.
However, documentation of the structure has been somewhat poor once it leaves the application.
This causes problems during analysis.
It's scary to make a change to a system that you don't quite fully understand.
In order to make those changes, you need some sort of feedback.

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
This contract is a form of shared understanding that the software is good, and that new features of bug fixes happen regularly.

Versioning doesn't solve all problems, but it does clearly communicate changes that have been made.

## The wild west of upgrading dependencies

So what do you do when there aren't such hardfast rules in place?
In my case, I knew exactly what behavior I was looking for and I had a reference of where this was solved before.
However, this is not always the case.
Your milage may vary, but there are some useful techniques and sources of information that you should take a look at first.

### Test the code for behavior

Behavior is easy to verify.
If you know what the behavior of the code you're running is supposed to be, youre already half way there.
You'll want to verify the behavior in a reproducible way.
Adding a new test case in an existing test suite is often a fairly easy way to do things.

### Audit the code
Now that you have a test, writing a patch is easy.
Determine the first location where the code has been updated to resolve the underlying issue.
This can be done by searching through the scm history for the patch.
Most likely, this is not the change you'll want to use.
Make sure that all the changes leading up to and slightly past are unrelated to the current behavior.

I don't have any stats, but a large project will probably have enough activities and users that issues are found fairly quickly.
For example, jobs that run on a cron schedule will break if any of the dependencies break.
This is often a good reason to have a semantic versioning system of some sort.
When in doubt, the code is the ultimate source of truth.

### Fork the code

One option that you have is to fork the code.
This might be a bit crazy though, why would you do this?
If you're use cases are simple, you may never reach any edge cases
I would advise against this though unless you have the capacity to fix bugs as they crop up.
However, it may be worthwhile creating a small patchset, and eventually propagating those changes upstream.

### Have a backup plan

Any large task you might want to do will definitnely have a million other people who want to the same exact thing.
Just choose another library and write it a slightly different way.
The time it takes help maintain libraries could end up being a very large yak to shave.
For me, I could just switch to a different json validation library perfectly fine.

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

Semantic versioning makes software maintainable by a community.
Libraries of code are meant to be used and read.
Open source libraries are even more so, but then they become a common.
The source of responsibility is then on the community in order to keep things stable.

Off to build more software.