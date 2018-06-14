---
layout: post
title: Diagnosing a bug in python-rapidjson
date:   2018-06-08 4:50:00 -0700
category: Engineering
tags:
    - Open Source
    - Libraries
    - Software Release
---

Subtle bugs in software can lead to long, frustrating debugging sessions.
I recently ran into a bug while building a system to validate JSON schemas against small samples of data.
The standalone project is designed to be run locally to increase the amount of feedback when developing schemas.
Batches of JSON are fed through an endpoint that returns a status code reflecting the result of validation.

Let's consider a toy example of performing schema validating on a phonebook.
The phonebook is represented as a collection of JSON strings delimited by newlines.

```json
{"first_name": "Dwight", "last_name": "Melton", "phone": "260-475-9121"}
{"first_name": "Jeffrey", "last_name": "Quinn", "phone": "323-636-8611"}
{"first_name": "Sandra", "last_name": "Bouck", "phone": "818-481-2026"}
```

The structure of these documents can be captured by a JSON Schema in the following way.

```json
{
  "type": "object",
  "properties": {
    "first_name": {"type": "string"},
    "last_name": {"type": "string"},
    "phone": {
      "type": "string", 
      "pattern": "^[0-9]{3}-[0-9]{3}-[0-9]{4}$"
    }
  },
  "additionalProperties": false
}
```

The phonebook entry is an object containing three typed fields.
The `phone` entry must match the pattern, or else it will be flagged by a validator.


In the Data Platform at Mozilla, schemas are used to validate browser telemetry at ingestion.
While there are currently 7 drafts of the specification, the JSON Schema draft v4 spec has the most implementations.
Our ingestion service validates the documents using a lua-binding of the rapidjson library.
The `edge-validator` uses the same library through a python binding to improve the cross project compatability.
At least, this was the intention when the validation varied wildly between the two applications.

In review of a recent PR, the validation error rate of the `edge-validator` on a sample of a particular document type was 100%.
If this were the case, we wouldn't have seen any data on our servers.
Something was inconsistent.
Fortunately, the generated integration reports were also useful for identifying issues in the application.
The errors on the main telemetry ping all shared a similar error message:

--- | ---
Type | additionalProperties
Schema Path |   #/properties/payload/properties/processes/properties/content/properties/histograms/additionalProperties/properties/values
Instance Path |  #/payload/processes/content/histograms/CYCLE_COLLECTOR_MAX_PAUSE/values/3

It looked like histogram measurements in telemetry were causing validation errors. 
This is the same data that can be found when looking at `about:telemetry` in Firefox.
The reporting tool for the validator included a comparison utility, designed to be the main feedback signal for developers.
Reports are generated between the master and local branch on a schema repo and diffed.
When I ran this comparison against master and dev, I noticed that the errors had increased between the two.

I later found out that the master branch was no longer being updated.
The dev branch was the defactor master and had diverged significantly.
By narrowing down the range through successive comparisons, I found the specific revision where things started to break down.
Earlier in the year, the histogram schema was made more strict.


```json
{
  "type": "object",
  "additionalProperties": false,
  "patternProperties": {
    "^[0-9]+": { "type": "integer" }
  }
}
```

The additional properties and patternProperties were used to verify that values in a histogram were being enforced.
I had a hunch, but now I had evidence that something was afoot.
Quickly, I saw myself in the same situation that had been resolved swiftly.
Both additional and pattern properties were prematurely calling assertions in the library.
In the lua bindings we used needed to pinned to a more recent revision of the source code.

With the original field guide on schemas in hand, I made a reliable test that captured the behavior I was observing.
All that needed to be done was to change the version of the rapidjson submodule.
I didn't need to perform a git bisection to find a stable version because I knew the stable version of the production lua library.
This stable version ended up incorporating the appropriate fixes backed by testing.

But as easy as it was to diagnose and fix the behavior, I noticed how difficult it is to maintain open-source software.
Software ends up being a contract between code and developers, but it's one that can be modified and improved.
Versioning is one way to communicate to others the readiness of the code to others.
The last release of rapidjson was from a year and a half ago, with no bug-fixes in sight.
There was an issue and a patch that were both fixed in the time spanned since that release, but no guarantee on the stability of the future changes.
How do you release software that other people depend on?

## The semantics of semantic versioning

The cadence of releases reflects software as a living thing.

Perhaps responsibility for a software roadmap should be given to a maintainer or creator.
The benevolent dictator for life has shown to be a somewhat useful model for some projects and maintainers.

But as an ecosystem evolves around a library, changes and bugs become part of the problem.
A single person can't do everything.
I also don't think committees solve every problem.
But semantic versioning helps alleviate issues around library compatibility by providing a clear set of understanding.

When the significant revision changes, there have been changes to the API that are breaking.
Python 2 and Python 3 is an infamous example, where the transition has been happening for over 10 years.
However, new libraries that do not support python 3 help break the mold, making it difficult to start a new project in the older API.
When the minor revision changes, there have been backward compatible changes that do not affect any current modules.
This means you can safely upgrade without worrying about breaking the code you've been writing, and you can expect some nice features too.
Finally, the final position is for the number of bugfixes that have been included in the library.

Semantic versioning forms a contract between the software, the developers, and the users.
When multiple projects are working together, there are known interoperability in protocols and APIs.
This occurs in open source software, where responsibility is shared between maintainers and contributors.
However, everyone benefits from the software because it is freely available.
This contract is a form of shared understanding that the software is right and that new features of bug fixes happen regularly.

Versioning doesn't solve all problems, but it does clearly communicate changes that have been made.

## The wild west of upgrading dependencies

So what do you do when there aren't such hard fast rules in place?
In my case, I knew exactly what behavior I was looking for, and I had a reference to where this was solved before.
However, this is not always the case.
Your mileage may vary, but there are some useful techniques and sources of information that you should take a look at first.

### Test the code for behavior

Behavior is easy to verify.
If you know what the behavior of the code you're running is supposed to be, you're already halfway there.
You'll want to verify the behavior reproducibly.
Adding a new test case in an existing test suite is often a relatively easy way to do things.

### Audit the code
Now that you have a test writing a patch is easy.
Determine the first location where the code has been updated to resolve the underlying issue.
This can be done by searching through the source-code history for the patch.
Most likely, this is not the change you'll want to use.
Make sure that all the changes leading up to and slightly past are unrelated to the current behavior.

I don't have any stats, but a massive project will probably have enough activities and users that issues are found reasonably quickly.
For example, jobs that run on a cron schedule will break if any of the dependencies break.
This is often a good reason to have a semantic versioning system of some sort.
When in doubt, the code is the ultimate source of truth.

### Fork the code

One option that you have is to fork the code.
This might be a bit crazy though, why would you do this?
If your use cases are simple, you may never reach any edge cases
I would advise against this though unless you can fix bugs as they crop up.
However, it may be worthwhile creating a small patchset, and eventually propagating those changes upstream.

### Have a backup plan

Any massive task you might want to do will definitely have a million other people who want the same exact thing.
Just choose another library and write it a slightly different way.
The time it takes help maintain libraries could end up being a very large yak to shave.
For me, I could just switch to a different json validation library perfectly fine.

## A happy ending

It turns out, dependencies can be handled further downstream.
Even if there isn't an official release, the behavior and characteristics of the software are enough to make a decision.
However, the cognitive load required because of due diligence is high.
Maintaining releases on a personal schedule requires testing, auditing, and being confident of changes.
This is workable, but it could be better.

This whole situation gave me an opportunity to contribute to a library that has been very useful.
I'm thankful that the library maintainer for python-rapidjson was responsive.
It was a nice feeling to be included as part of a new release that actually fixes real problems.
Maybe consistently releasing software is fundamental for building open source communities.
There is a sense of responsibility that comes from making changes that matter because bug-fixes are for the common good.

Semantic versioning makes software maintainable by a community.
Libraries of code are meant to be used and read.
Open source libraries are even more so, but then they become universal.
The source of responsibility is then on the community to keep things stable.

Off to build more software.
