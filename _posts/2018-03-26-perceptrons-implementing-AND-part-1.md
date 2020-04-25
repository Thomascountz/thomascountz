---
title: Perceptron Implementing AND | Part 1
subtitle: Learning Machine Learning Journal \#2
author: Thomas Countz
---


In
<a href="./2018-03-23-perceptrons-in-neural-networks.html" >Learning Machine Learning Journal #1</a>,
we got my feet wet learning about perceptrons. Inspired by
<a href="http://michaelnielsen.org/" class="markup--anchor markup--p-anchor">Michael Nielsen</a>’s
<a href="http://neuralnetworksanddeeplearning.com/index.html" class="markup--anchor markup--p-anchor">Neural Networks and Deep Learning</a>
book, today, the goal is to expand on that knowledge by using the
perceptron formula to mimic the behavior of a logical `AND`.

------------------------------------------------------------------------

As a programmer, I am familiar with logic operators like `AND`, `OR`,
`XOR`. Well, as I’m learning about artificial neurons, it turns out that
the math behind perceptrons,
<a href="./2018-03-23-perceptrons-in-neural-networks.html" class="markup--anchor markup--p-anchor">see more here</a>,
can be used to recreate the functionality of these binary operators!

As a refresher, let’s look at the logic table for `AND`:

``` graf
 A   B  | AND 
--- --- |-----
 0   0  |  0
 0   1  |  0
 1   0  |  0
 1   1  |  1
```

#### Let’s break it down.

To produce a logical `AND`, we want our function to output `1`, only
when both inputs, `A`, and `B`, are also `1`. For every other case, our
`AND` should output `0`.

Let’s take a look at this using our perceptron model from
<a href="./2018-03-23-perceptrons-in-neural-networks.html" class="markup--anchor markup--p-anchor">last time</a>,
with a few updates:

The equation we ended up with looks like this:

<figure>
<img src="https://cdn-images-1.medium.com/max/800/1*T_mQVKH0PKS97waJ-RkDYg.png" class="graf-image" alt="" /><figcaption><a href="https://en.wikipedia.org/wiki/Perceptron" class="markup--anchor markup--figure-anchor">https://en.wikipedia.org/wiki/Perceptron</a></figcaption>
</figure>

And when we insert our inputs and outputs into our model, it looks like
this:

<figure>
<img src="https://cdn-images-1.medium.com/max/1200/1*ISAFhD3s-nEkpuywceG7Cg.png" class="graf-image" alt="" /><figcaption>Logical AND with Perceptrons</figcaption>
</figure>

*Side note: This model of a perceptron is slightly different than the
last one. Here, I’ve tried to model the weights and bias more clearly.*

All we’ve done so far, is plug our logic table into our perceptron
model. All of our perceptrons are returning `0`, except for when both of
our inputs are “activated,” i.e. when they are `1`.

What is missing from our model, is the actual implementation detail; the
weights and biases that would actually give us our desired output.
Moreover, we have four different models to represent each state of our
perceptron, when what we really want, is one!

#### So the question becomes how do we represent the *behavior* of a logical `AND`, i.e., what *weights* and *biases* should we input into our model to produce the desired output?

<figure>
<img src="https://cdn-images-1.medium.com/max/800/1*0J193XBx1WolJacFwxa6Ug.png" class="graf-image" alt="" /><figcaption>What should our weights and bias be?</figcaption>
</figure>

------------------------------------------------------------------------

**The first thing to note is that our weights should be the same for
both inputs,** `A` **and** `B`**.**

If we look back at our logic chart, we can begin to notice that the
position of our input values does not affect our output.

``` graf
 A   B  | AND 
--- --- |-----
 0   0  |  0
 0   1  |  0
 1   0  |  0
 1   1  |  1
```

For any statement above, if you swap `A` and `B`, the `AND` logic still
stands true.

**The second thing to note is that our summation + bias,**
`w · x + b`**, should be negative, except when both A and B are equal to
1.**

<figure>
<img src="https://cdn-images-1.medium.com/max/600/1*vTGew0ODt-weO-ceY3fu1A.jpeg" class="graf-image" alt="" /><figcaption><a href="https://en.wikipedia.org/wiki/Perceptron" class="markup--anchor markup--figure-anchor">https://en.wikipedia.org/wiki/Perceptron</a></figcaption>
</figure>

If we take a look back at our perceptron formula, we can generalize that
our neuron will return `1`, whenever our input is positive, `x > 0`, and
return `0`, otherwise, i.e., when the input is negative or `0`.

**Now, let’s work our way backwards.**

If our inputs are `A = 1` and `B = 1`, we need a positive result from
our summation, `w · x`; for any other inputs, we need a `0` or negative
result:

``` graf
1w + 1w + b  > 0
0w + 1w + b <= 0
1w + 0w + b <= 0
0w + 0w + b <= 0
```

We know that:

-   <span id="bde2">`x * 0 = 0`</span>
-   <span id="1593">`1x + 1x = 2x`</span>
-   <span id="aeda">`1x = x`</span>

So we can simplify the above to:

``` graf
2w + b > 0
w + b <= 0
b <= 0
```

Now we know that:

-   <span id="5553">`b` is `0` or negative</span>
-   <span id="f1ef">`w + b` is `0` or negative</span>
-   <span id="9cf3">`2w + b` is positive</span>

We also know that:

-   <span id="a452">`b` cannot be `0`. If `b = 0`, then `2w > 0` and
    `w <= 0`, which cannot be true.</span>
-   <span id="5fcf">`w` must be positive. If `w` were negative, any
    `2w`, would also be negative. If `2w` were negative, adding another
    negative number, `b`, could never result in a positive number, so
    `2w + b > 0` could never be true.</span>
-   <span id="c4df">If `b` is negative and `w` is positive ,
    `w — b = 0`, so that `w + b <= 0`.</span>

#### That’s it!

We now know that we can set `b` to any negative number and both `w`’s to
its opposite, and we can reproduce the behavior of `AND` by using a
perceptron!

For simplicity, let’s set`b = 1`, `w1 = -1`, and `w2 = -1`

<figure>
<img src="https://cdn-images-1.medium.com/max/800/1*VaMxhQ23gPq53GK-ozeKGQ.png" class="graf-image" alt="" />
</figure>

### Resources

-   <span
    id="1277"><a href="http://toritris.weebly.com/perceptron-2-logical-operations.html" class="markup--anchor markup--li-anchor">http://toritris.weebly.com/perceptron-2-logical-operations.html</a></span>
-   <span
    id="fa06"><a href="https://www.youtube.com/watch?v=aircAruvnKk&amp;t=6s" class="markup--anchor markup--li-anchor">But what *is* a Neural Network? | Chapter 1, deep learning</a></span>
-   <span
    id="5d44"><a href="https://www.youtube.com/watch?v=IHZwWFHWa-w" class="markup--anchor markup--li-anchor">Gradient descent, how neural networks learn | Chapter 2, deep learning</a></span>
-   <span
    id="a419"><a href="https://www.youtube.com/watch?v=Ilg3gGewQ5U" class="markup--anchor markup--li-anchor">What is backpropagation really doing? | Chapter 3, deep learning</a></span>
-   <span
    id="e452"><a href="https://www.youtube.com/watch?v=tIeHLnjs5U8" class="markup--anchor markup--li-anchor">Backpropagation calculus | Appendix to deep learning chapter 3</a></span>
-   <span
    id="bc91"><a href="http://neuralnetworksanddeeplearning.com/index.html" class="markup--anchor markup--li-anchor">Neural Networks and Deep Learning</a>
    by
    <a href="http://michaelnielsen.org/" class="markup--anchor markup--li-anchor">Michael Nielsen</a></span>
-   <span
    id="8261"><a href="https://medium.com/@suffiyanz/getting-started-with-machine-learning-f15df1c283ea" class="markup--anchor markup--li-anchor">Getting Starting with Machine Learning</a></span>
-   <span
    id="03dd"><a href="https://betterexplained.com/articles/linear-algebra-guide/" class="markup--anchor markup--li-anchor">And Intuitive Guide to Linear Algebra</a></span>
-   <span
    id="52b6"><a href="https://appliedgo.net/perceptron/" class="markup--anchor markup--li-anchor">Perceptrons — the most basic form of a neural network</a></span>
-   <span
    id="91a4"><a href="https://en.wikipedia.org/wiki/Perceptron" class="markup--anchor markup--li-anchor">Perceptron — Wikipedia</a></span>
