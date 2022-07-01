# Week 4

The fourth week of lectures focuses on comparing models and understanding the implications of the causal model. The first model builds up the marriage model to compare the predictive performance. It turns out that including all variables increases performance, but reduces the ability to infer what the parameters of the model actual means due to confounds. The second question involves redoing the fox analysis. The final question involves building a model for cherry blossoms.

The last question was the most difficult because the analysis involved simulation. Here, it was useful to actually walk through the solution because I had trouble with extending the model to new data when fit with standardized data. It turns out it's straightforward to use the training dataset's mean and standard deviation to convert new values into z-scores, and then to do the inverse after taking posterior samples.

- https://colab.research.google.com/drive/1wuPxytRq82La12sVntlgk_EbL0oGACD1#scrollTo=oZooXG5UYMZ1
- https://github.com/rmcelreath/stat_rethinking_2022/blob/main/homework/week04.pdf
- https://github.com/rmcelreath/stat_rethinking_2022/blob/main/homework/week04_solutions.pdf
