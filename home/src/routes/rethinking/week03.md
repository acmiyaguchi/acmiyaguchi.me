# Week 3

The third week of lectures focuses on confounds and controls. The most important concept in this week is the backdoor criterion on two DAGs: a fox food network and a smoking/stroke dataset. This week ends up being an easy assignment, since the most math involved is interpreting linear regressions with respect to a causal model.

One area of modeling that caught me off guard was the use of standardized data for modeling. I understand it makes it easier to model when the variables involved have zero mean and unit variance, but it's not intuitive that the parameters (alpha and beta) have different values. More-so, I'm not sure how to do inference on new data, when data has been standardized relative to the current dataset. On the other hand, standardizing the dataset makes it easier to come up with reasonable priors and is also easier to interpret.

I also had some difficulty with interpreting the second order effects in the DAG for problem 3 -- I didn't realize until reading the solutions that the introduction of node U prevents causal inference of the indirect effects.

- https://colab.research.google.com/drive/1w1DsDJYVEAajWZHFcDYuGynTS4D_I45q#scrollTo=VT3hLG60wqsV
- https://github.com/rmcelreath/stat_rethinking_2022/blob/main/homework/week03.pdf
- https://github.com/rmcelreath/stat_rethinking_2022/blob/main/homework/week03_solutions.pdf
