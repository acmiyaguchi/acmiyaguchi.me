---
layout: post
title: Monitoring Earth through Remote Sensing
date:   2018-06-01 20:00:45 -0700
category: Science
tags:
    - software
    - computer vision
    - signal processing
    - remote sensing
---

The ability to predict the weather in a predictable way has forged a path for large bottlenecks in the development of civilization.
Farmers and their crops rely on a regular pattern of weather over the seasons, sea-faring fishermen the winds and storms.
The regularity of the various factors involved with weather, like geographical features and rotational pattern of the earth, allow us to forecast the weather for the weekend.


In the age of information, the resolution of data that we can collect is staggering.
The National Oceanic and Atmospheric (NOAA) collects a massive amount of data that goes into predicting the weather.
The number of satellites launched into low orbit today is much larger than it was 10 years ago.
This is because it is increasingly cost-effective to launch satellites for communication and measurement.
The number of high bandwidth sensors like spectral cameras have made it possible to map the entire planet everyday in a high-dynamic range.


Remote sensing is a way of percieving the physical world through remote data collection.
Radar is a method of remote sensing that involves emitting a wave and measuring the time it takes to come back.
Bats and dolphins are well known for using this to adapt to low light environment through high frequency clicking.
Eyes and vision are an even more basic adaption that was developed early in timescale of life on Earth.
Vision enables a feedback loop for sensing and acting, which can contribute to understanding.


Vision is a embarassingly parallel problem.
The amount of parallel computation is increasing rapidly with the number of small cores that can be fit onto a single unit.
The number of floating point operations that can be done in a second is a good benchmark of this capability.
Graphics Processing Units (GPUs) and Tensor Processing Units (TPUs) are designed particularlly well for the data problem.
They are able to take advantage of data parallelism and linear algebra to process very high bandwidth signals.
Algorithms such as deep neural networks and kernel methods can be implemented efficiently in hardware.

Satellite imagery requires efficient usage of computation.
One example may be to detect large changes in areas of land such as the Amazon to monitor the progress of illegal forestry.
This can be done by comparing the spectral components of an image against each other with a simple threshold.
The fourier transformation can be applied to spectral data in an efficient way.
This algorithm reduced the complexity of a computing the spectrum from O(n^2) to O(nlogn).
This is a massive speedup.

The reason that this works so well is because there is a relationship between points in space.
The laplace and fourier transformation are often seen in the context of linear and time invariant systems in the context of time.
This is because these systems are dependent on values relative to the current time.
These transformations also work in space, but the interpretation is slightly different.
