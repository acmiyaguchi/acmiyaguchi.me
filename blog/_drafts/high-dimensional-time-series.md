---
layout: post
title: High Dimensional Time Series Analysis
date:   2018-07-01 20:00:45 -0700
category: Science
tags:
    - time series
    - signal processing
---

## Problem Definition and Examples

High-dimensional time-series data provide real challenges to techniques available in modern signals processing and machine learning toolkits.
The exponential increase of computers and sensors means that there is more data available than can stored to disk.
This means we can measure large, dynamical systems and model how they work.
This ability has lead to the growth of computational biology and econometrics.

A time series model can be characterized by the ability to interpolate, and forecast, and analyze trends.
For example, weather models take into account massive amounts of atmospheric data to create a fairly accurate seven day forecast.

Because of the growing amount of data involved with networks of devices and the environment, the ability to observe trends and patterns can help design increasingly robust systems with more feedback.

The data is often represented as an n-dimensional time series or as a tensor.
Some effective frameworks for data processing utilize regression and state space models.
Efficient methods for clustering assume that measurements are discrete.

The sensors can be unreliable.
 Because of this, data points are often rejected or corrected to improve robustness of an algorithm.
 This may happen implicitly when adjusting hyperparameters when fitting a machine learning model.

## As a dimensionality reduction problem (on computational efficiency)

There are computationally efficient ways of processing the data when treated as a dimensionality reduction problem.

Dimensionality reduction is effectively downsampling and quantization.
This allows for efficient forecasting and clustering.

[ downsampling, quantization graphs ]

The interesting quality of high dimensional time series is the spatial component of the data.
For example, given a large amount of spectral data, we may notice that certain areas are actually covariates and vary with each other.
A concrete example is the effect of mountains in creating a mediterranean climate. Mountain ranges cause moisture blow from the sea to precipate before making it inland, causing seasonal raining seasons.
The effects of many smaller microclimates can contribute to the behavior of the overall climate, which can be modeling to create a more effective forecast.

One effective way of modeling spatial relationships is to discretize space into small points and relate similar spaces together

[ visualization of svd ]

# The future of time, space, and data mining

The implications for efficient algorithms are immediate for understanding complex processes such as climate models, electricity grid markets, and gene expression patterns.
