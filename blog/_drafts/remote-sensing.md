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
The convolution operator works great, the kernel trick in SVMs are proof of this.
The laplace and fourier transformation are often seen in the context of linear and time invariant systems in the context of time.
This is because these systems are dependent on values relative to the current time.
These transformations also work in space, but the interpretation is slightly different.
They represent the geometry of the space in more than one dimension.


If you discretize space and weight it properly, you can treat the problem as a graph.
This type of approach is used to build graphical models that can perform image segmentation.
There is a bijection between a graph representation of nodes and edges to an adjency list.
This is often used to cluster graphs.
One way to cluster a graph is to run the SVD or CUR decomposition to obtain a lower dimensional representation of the graph.
This latent space can be used to find appropriate partitions in a graph to cluster by.
This form of dimensionality reduction helps tame the massive datasets that are being created everyday.


A more difficult problem than change detection is forecast prediction.
The remote sensing data collected by a fleet of satellites can be used to predict the weather.
These models are done in small blocks, where they are created using complex dynamical models.
Satellite data can be reduced in dimension to reduce the complexity of non-linear models.
The globe is chunked into parts, and each part is reduced in dimension separately.


Each cell can vary with each other at various different resolutions.
We can reduce the large covariance matrix by penalizing for sparsity.
This is a problem of l1 regularization.
The inverse of the covariance matrix is an even easier problem to solve for.
The induced sparsity improves the time-series analysis and makes it tractable.

Laplacian Eigenmaps find a low-dimensional manifold by taking into account the geometry of the data.
This is because there is some neighborhood-effect, or areas of localized phenomena.



In practice, weather is actually a very difficult problem.
Even though we have a large data collection capacity, the resources are difficult for most individuals to access.
The models are also very complex and is a very deep domain.
Data driven models are having success, see the predicted trajectory of hurricane paths.
SVD is used often because data is high dimensional.
Techniques for processing large amounts of spatial and time series data are generally useful for simulations.


This type of model is common in other areas where there are a large number of signals.
While weather forecasting is one example of large scale data collection, there are other fields.
Econometrics looks at the status of many small indicators to monitor the health of the entire economy.
If all transactions were captured, the resolution of the data would be very fine and hard to compute.
These market based models are useful fo things such as traffic modeling and predicting quanties.
Data is quickly becoming larger than we could ever hope to process.
We have to become efficient at recognizing patterns so we can take action.


soft thresholding
fftlasso
convolution sparse coding
spectral clustering
precision matrix
laplacian eigenmap to determine lower dimensional embedding
textures

http://www.goes.noaa.gov/GSSLOOPS/wcwv.html

http://scikit-learn.org/stable/auto_examples/covariance/plot_sparse_cov.html

http://scikit-learn.org/stable/auto_examples/linear_model/plot_logistic_l1_l2_sparsity.html

http://papers.nips.cc/paper/5626-learning-convolution-filters-for-inverse-covariance-estimation-of-neural-network-connectivity.pdf

GENERALIZED LAPLACIAN PRECISION MATRIX ESTIMATION FOR GRAPH SIGNAL
PROCESSING
https://pdfs.semanticscholar.org/4e77/48cfd19e115de495fc2d2801fa661b5c1b7c.pdf

https://graphics.stanford.edu/courses/cs468-10-fall/LectureSlides/16_spectral_methods1.pdf

Markov Random Fields in Image Segmentation
https://inf.u-szeged.hu/~ssip/2008/presentations2/Kato_ssip2008.pdf