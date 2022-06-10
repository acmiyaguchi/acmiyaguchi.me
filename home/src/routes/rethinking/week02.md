# Week 2

The second week of lectures focuses on linear regression and getting practice with the tooling. This problem set revolves around the Howell dataset, which involves several hundred individuals' height, age, weight, and sex.

The first question involves building a linear regression model of height on weight. The question is the inverse relationship to the example in chapter 4 of the book, which involves the relationship between weight on height. I spent a lot of time learning `pymc3` and translating the problem using a new tool. The first few hurdles here had to do with a few inconsistencies in the `pymc3` materials -- `compatibility_interval` has been replaced with `hdi_prob` inside of `az.summary`, and `az.hdp` has been replaced with `az.hdi`. It took me longer than I'd like to realize that I needed to create the model summary via `sample_posterior_predictive`. `pymc3` requires declaring the data as an explicit variable to apply out of sample data for prediction. Finally, I found that my compatibility intervals did not match the solution at all. For example, for an individual with a height of 140cm, I get 35.0/48.0kg on the lower/upper 89th percentile for the compatibility interval, while the solution has 29.1/42.8kg. I am using the default MCMC method via `pymc3` instead of the quadratic approximation in the book. Still, I would assume that the compatibility interval and uncertainty are derived from the data and not by the method to compute the model. The difference is not apparent after comparing my solution to the professors, so I'm moving on since I've gotten the general gist of the shape of the problem.

The second problem involves finding the total causal effect of age on weight. The problem includes DAG that puts height as an indirect influence on weight, but this is a red-herring. I ended up implementing a multiple-regression model involving the effects of age and height, but the solution involves a linear regression of age on weight. I don't completely understand why we can disregard the effect of height on weight -- it may be because, as a cofound, it doesn't introduce new information to the model. The result of `az.summary` matched the solution closely after I corrected my model, which was comforting after the CI of the first problem.

The last problem is a linear regression with a categorical variable. This problem was probably the easiest out of the three, now that I had a few examples of building models with `pymc` out of the way. The most challenging piece was modeling the actual categorical value `male`. The book in chapter 5 exemplifies doing this using a declarative syntax that I find pleasing. In `pymc`, I have to model the effects explicitly (e.g., dummy code the variable and compute the dot-product).

In R:

```R
mu <- a[sex] + b[sex]*A
```

In Python:

```python
mu = pm.Deterministic("mu",
    (a[0] + b[0] * age) * male
    + (a[1] + b[1] * age) * (1 - male)
)
```

Plotting out the highest density interval is relatively easy, though, and there's a clear difference between the growth of males and females over ages 0 and 13.

I decided not to the challenge problem this week instead of optimizing for actually getting through the material. If I manage to get through all the problem sets, I'll consider returning and doing these problems to refresh my understanding with a better overview of the material. But otherwise, staying too long in one place might be limiting.

- https://colab.research.google.com/drive/1zZTwxb0IG4ZCrvGEh_Aa0A_QI9vSJUZ0
- https://github.com/rmcelreath/stat_rethinking_2022/blob/main/homework/week02.pdf
- https://github.com/rmcelreath/stat_rethinking_2022/blob/main/homework/week02_solutions.pdf
- https://github.com/pymc-devs/pymc-resources/blob/main/Rethinking/Chp_04.ipynb
- https://github.com/pymc-devs/pymc-resources/blob/main/Rethinking/Chp_05.ipynb
- https://discourse.pymc.io/t/how-do-i-predict-on-new-unseen-real-data-using-pm-sample-posterior-predictive/6467
- https://bpostance.github.io/posts/pymc3-predictions/
