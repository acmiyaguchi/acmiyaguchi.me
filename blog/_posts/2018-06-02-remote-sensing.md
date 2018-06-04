---
layout: post
title: Monitoring Earth through Remote Sensing
date:   2018-06-02 22:47:00 -0700
category: Science
tags:
    - software
    - computer vision
    - signal processing
    - remote sensing
---

Significant shifts in human civilization came from being able to understand patterns in our environment and use them to our advantage.
The agricultural and industrial revolutions began with an intution about the seasonal rainfall and the life cycle of plants.
Sailors were able to harness the regular flows of the trade winds to make the world traversable in just under 2 years.
Today, we have communication systems that can continuously image the Earth for monitoring and understanding.
The National Oceanic and Atmospheric (NOAA) collects data for monitoring and assessing the situation of our oceans and climate.
One of their projects is the Climate Forecast System, a collection of measurements for many variables that supports a resolution of half a degree in an aggregated form. [1]
Now it is becoming cost-efficient to launch new instruments in weather balloons and cube satellites.
With the aid of a computer, we can observe environment around us without having to rely on our physical senses.

The sensory adaptions formed out of biological systems.
Bats and dolphins use echolocation to map their environment where eyes would typically fail.
They can detect slight shifts in the pitch of the sound as it bounces back from moving objects.
We have been able to apply our understanding of this Doppler effect to map the earth's oceans and surfaces through ship, plane, and satellite.
For example, the Sentinel-1 constellation collects high-resolution synthetic-aperture radar (SAR) imagery for monitoring land and sea.
The satellites can support monitoring of icebergs and map oil spills through reliable measurements.[2]
Action and the option to act rely on sense through awareness in any system.

## A Parallel Programming Model

| ![hmm]({{ "/assets/blog-01/GSSLOOPS-wcwv-1.jpg" | absolute_url }}) |
|:--:|
| *__Figure__: A map of water moisture and cloud cover from the NOASS* |

Analysis of the data requires a network of computers to run in a reasonable length of time.
A recent study of high-performance computing (HPC) software used data from the Climate Forecast System at a 360 x 720 x 41 (latitude x longitude x depth) by 6-hour resolution yielding a 2.2TB matrix of known variables. [3]
The amount of data is even higher if we consider imaging data, like the earth view of Google Maps.
A San Francisco startup, Planet, collects over 5TB of data a day in the form of images collected by a constellation of small cube satellites. [4]
Fortunately, the infrastructure to support computational needs are become more mature.

Graphics and Tensor Processing Units (GPUs and TPUs) have become commonplace in computer vision and neural networks.
The abundance and regularity of data have fueled the growth of more efficient hardware.
The number of floating point operations per second (FLOPS) reflects the efficiency of a processing unit.
The global flux of FLOPS has increased through GPUs to support demand for digital processing needs.
The GPU started as a dedicated coprocessor designed to paint an image to a screen quickly.
Designed to perform basic image manipulation tasks, they also formed the basis for general-purpose computing on GPUs.

General-purpose computing on GPUs relies on the solid foundations of linear algebra to exploit inherent data parallelism.
OpenCV, computer vision software with a community of over 47 thousand, is a library for writing efficient, real-time applications. [5]
Linear operators like convolutions can be used to apply filters or kernels to images.
Convoluting an edge-detection kernel with an image produces another image where the values represent the likelihood of being an edge.
The TensorFlow library is another software library that was designed for machine learning.
Because of the regularity of n-dimensional convolutions written in software, the TPU coprocessor was designed and manufactured.
The programming interface is more powerful than the hardware it supports, so it's likely that more efficient hardware will be built.


<style>
#images {
    white-space: nowrap;
}
</style>

<div id="images" class="array">
<a title="By Michael Plotke [CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0)], from Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Vd-Orig.png"><img width="50%" alt="Vd-Orig" src="https://upload.wikimedia.org/wikipedia/commons/5/50/Vd-Orig.png"></a>

<a title="By Michael Plotke [CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0)], from Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Vd-Edge1.png"><img width="50%" alt="Vd-Edge1" src="https://upload.wikimedia.org/wikipedia/commons/8/8d/Vd-Edge1.png"></a>
</div>

*__Figure__: An image and the image convolved with an edge-detection kernel. From [Kernel (Image Processing), Wikimedia Commons](https://en.wikipedia.org/wiki/Kernel_(image_processing))*

Distributed data processing libraries like Spark have reduced the complexity of managing powerful computing clusters.
By utilizing a network of computers and available global mapping information, we can build systems to detect changes on a large scale.
For example, satellite imagery can be used to determine areas of conservation based on historical patterns of deforestation in the Southern Tropic. [6]
There are many techniques for processing large datasets, but one particularly efficient one is to treat image data as spectral data.
The colors and intensity of an image can be used to extract meaningful patterns.
Sometimes infrared and ultrasonic waves are measured in a process called hyperspectral imaging.
The spectrum recorded to a map, where every group of observations has a neighbor.
This data has a natural grid-like form, where little effort is necessary to parallelize processing.

## Finding Patterns in Earth's Image

With a full image of the surface of the earth, we can start to ask questions about the state of the environment.
For example, a health model of the earth may include a distribution of terrain and how they change over time.
The global image is broken into common areas and categorized based on its properties.
One method is to segment areas of high contrast using the convolution operator and edge-detection kernel.
However, the convolution algorithm requires time proportional to the product of the image and kernel dimensions.
The convolution theorem helps us bound this operation by replacing an expensive convolution with an efficient change of base and multiplication.
This theorem is the foundation for efficient signals processing techniques.

<a title="By Brian Amberg [CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0) or GFDL (http://www.gnu.org/copyleft/fdl.html)], from Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Convolution_of_box_signal_with_itself.gif"><img width="100%" alt="Convolution of box signal with itself" src="https://upload.wikimedia.org/wikipedia/commons/6/6e/Convolution_of_box_signal_with_itself.gif"></a>

_**Figure**: The convolution of a box signal with itself runs in time proportional to the number of discrete samples taken. From Wikimedia Commons._

In space, we can use this to look at the spectrum of different stars.
If we a hyperspectral image of the night sky, we can apply a Fourier transform to look at the range and intensities of star radiation.
By looking for discontinuities in this data, we have generated the terrain of the sky by breaking it into areas and categorizing the stars.
The fast Fourier transform (FFT) calculates an orthonormal base in the frequency domain in order n*log(n) time complexity where n is the product of image dimensions.
Because of its efficiency and broad scientific use, the FFT has been described as "the most important numerical algorithm in our lifetime." [7]
This process of transforming between domains is useful for mastering the shortcomings of otherwise powerful techniques.

Another technique for mapping terrain in a large scale dataset is to partition the data into cells, and the treat each of the cells as a node in a graph.
The edges of the graph represent the distances between the current cell and its neighbors.
This topological approach can be used to build spectral and graphical models for clustering and segmentation.
As the spatial and frequency domains in the Fourier transform, there is a natural transformation between graphs and their matrix form.
By removing the diagonal of the graph matrix, we obtain a similar spatial image of the graph called the Laplacian matrix.
In fact, the eigenvectors of this matrix have a similar interpretation to the Fourier transform. [8]
Both of these transformations form an orthonormal basis in a spectral domain that can be processed using the same toolbox.

| ![sparsity]({{ "/assets/blog-01/sphx_glr_plot_logistic_l1_l2_sparsity_001.png" | absolute_url }}) |
|:--:|
| *__Figure__: The effect of regularization on sparsity in a logistic regression of the MNIST dataset from [scikit-learn](http://scikit-learn.org/stable/auto_examples/linear_model/plot_logistic_l1_l2_sparsity.html)* |

This spectral decomposition has extensive uses because there are efficient algorithms for processing trillions of sparse data points in space.
For example, the PageRank algorithm pioneered by Google uses a method called power iteration to find the eigenpairs of the web hyperlink matrix.
Once the data has been reduced in dimension through a decomposition like SVD or CUR, the discontinuities in the latent space determine the appropriate places to segment the graph.
Dimensionality reduction is a fundamental tool in the analysis of massive datasets.

Detection is the first step in being able to handle the influx of new sensory data.
In addition to being able to determine the lay of the land and contrast different areas, we are often interested in being able to forecast a particular event into the future.
The weather forecast is often done by analyzing data over a large area in small cells and modeling the complex dynamical system.
The broader problem of forecasting from many, high-resolution streams of data falls under high-dimensional time series analysis.
The Climate Forecast System is one example, where each dimension represents a variable or state.
However, analyzing thousands of variables at the same time is difficult for most time-series algorithms. [9]
One way to tackle this problem is to aggregate streams of data together by clustering similar series.
The covariance matrix and the inverse precision matrix can be used to see how different variables correlate and partially correlate with each other. [10]
Inducing sparsity in the precision matrix can remove spurious relationships between series, while the eigenvectors of the covariance matrix aid in clustering.

## Thoughts

| ![water]({{ "/assets/blog-01/CFS - 1-15March1993_Atmospheric_Precipitable_Water-small.gif" | absolute_url }}) |
|:--:|
| *__Figure__: A simulation of precipitable water from the NOAA at [1]* |

In practice, the complexity of the data with our current computational resources prevents us from producing confident weather forecasts beyond a few weeks.
Despite the growing amount of available information, computational power and domain intuition are still limiting resources.
However, models driven by massive data have bootstrapped a feedback loop necessary for discovery and refinement.
In particular, there are ways to exploit the geometry of spatial data to increase the overall knowledge about the state of the earth.
When paired with standard techniques for dimensionality reduction and time series, remote sensing becomes a tool that can help chart a path to coexistence with our environment.


## References

* [1] https://www.ncdc.noaa.gov/data-access/model-data/model-datasets/climate-forecast-system-version2-cfsv2
* [2] https://earth.esa.int/web/guest/missions/esa-operational-eo-missions/sentinel-1
* [3] https://www2.eecs.berkeley.edu/Pubs/TechRpts/2016/EECS-2016-151.pdf
* [4] https://www.planet.com/products/platform/
* [5] https://opencv.org/
* [6] http://journals.sagepub.com/doi/abs/10.1177/194008291300600101
* [7] https://spectrum.ieee.org/computing/software/a-faster-fast-fourier-transform
* [8] https://pdfs.semanticscholar.org/4e77/48cfd19e115de495fc2d2801fa661b5c1b7c.pdf
* [9] https://www.cs.utexas.edu/~rofuyu/papers/tr-mf-nips.pdf
* [10] https://repositori.upf.edu/bitstream/handle/10230/560/691.pdf?sequence=1
