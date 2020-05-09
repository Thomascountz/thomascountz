---
title: FastBook Chapter 4 Questions & Notes
author: Thomas Countz
layout: post
tags: ["fastai", "machine learning", "fastbook"]
---

[Fastai](https://www.fast.ai/), known for it's MOOCs, is working on a book, [Fastbook](https://github.com/fastai/Fastbook) to go along with their new MOOC starting July 2020. In my eagerness, I've been going through the draft of the book (linked above, though they may remove it after publication) and have been coding alongside on [Kaggle](https://www.kaggle.com/thomascountz). At the end of each chapter of the book is a list of questions for the reader/students to answer. I've found these questions to be rigorous and useful to deepen my understanding.

This blog post might not be useful to anyone besides myself, but I want to keep my answers to these questions as a reference somewhere other than a Kaggle notebook.


### How is a greyscale image represented on a computer? How about a color image?

A greysale image is represented by a matrix/rank 2 tensor/grid of pixels with a value between 0 and 255. Color images are a rank 3 tensor, height and width along two dimensions and third dimension representing values between 0 and 255 for redness, greenness, and blueness.

### How are the files and folders in the MNIST_SAMPLE dataset structured? Why?

There are two directories: `/train` and `/valid`, which each contain two directories: `/3` and `/7`. Inside those directories are images of the respective digit. The `train/` directory contains the majority of images to be used to train a model likewise the `/valid` directory contains images to validate a model. There's also a `labels.csv` file which likely contains a mapping between file names and digit label.

### Explain how the "pixel similarity" approach to classifying digits works.

The idea behind this approach was to look at all of the images for a given digit and compute the average value for each pixel across all images. Then, by comparing an unlabeled digit to that "average" digit, we could determine how similar or dissimilar the unknown image was to the known average.

### What is a list comprehension? Create one now that selects odd numbers from a list and doubles them.

It's a way of mapping over an enumerable object in Python

```python
[i * 2 for i in range(20) if i % 2 == 0]
```

### What is a "rank 3 tensor"?

A rank 3 tensor is a tensor with three dimensions, such as a color photo.

### What is the difference between tensor rank and shape? How do you get the rank from the shape?

A tensor's rank is equivalent to the number of dimensions a tensor has. It's shape is how many values exist in each dimension. Because the shape tells us the number of values per dimension, we can determine the number of values returned to determine the rank.

### What are RMSE and L1 norm?

RMSE, or root mean square error is the average difference of the prediction and the label squared and then 2nd rooted?

```python
def mse(y, yhat): ((y - yhat)**2).mean().sqrt()
```

L1 norm is the average of the absolute value of the difference between y and yhat

```python
def l1(y, yhat): (y - yhat).abs().mean()
```

### How can you apply a calculation on thousands of numbers at once, many thousands of times faster than a Python loop?

Broadcasting.

### Create a 3x3 tensor or array containing the numbers from 1 to 9. Double it. Select the bottom right 4 numbers.

```python
(torch.reshape(torch.arrange(1, 10), (3, 3)) * 2)[-2:,-2:]
```

### What is broadcasting?

 Broadcasting is traditionally used to support computation between two unequal tensor with the side effect of not needing to copy any data. This side effect can be taken advantage of for applying calculation to two tensors even if they are equal in rank. 

This happens implicitly in Pytorch when operating of two vectors, for example:

Non-broadcasting: slow
```python
>>> a = [1, 1, 1]
>>> b = [1, 1, 1]
>>> c = [x + y for x, y in zip(a, b)]
[2, 2, 2]
```

Broadcasting: fast
```python
>>> a = tensor([1, 1, 1])
>>> b = tensor([1, 1, 1])
>>> a + b
tensor([2, 2, 2])
```

### Are metrics generally calculated using the training set, or the validation set? Why?

> A metric is a function that measures quality of the model's predictions using the validation set, and will be printed at the end of each epoch. —Fastbook, Ch. 4

We use a metric to judge our network's ability to accurately predict outputs for data is hasn't seen before.

### What is SGD?

Gradient Descent is the process by which we update the weights/parameters/coefficients of our model in order to minimize the loss function. By taking the gradient/derivative of our loss function, we can determine how a change in our parameters would result in a change to the output. We can use that gradient to update our weights in proportion to the learning rate. Stochastic just means measure loss and update our weights in in "batches." Some definitions say that "Stochastic" means we calculate and update for the entire training set.

### Why does SGD use mini batches?

Updating parameters after every training example takes a long time and can mean sporadic jumps in parameters after each example as the network tries to optimize for each individual example. Waiting until after going through the entire dataset can be impossible for large datasets that don't fit into memory. It's inefficient and doesn't necessarily provide better results. Mini-batches solve both of these problems. We reduce the variance between each parameter update which can smooth out convergence, and we don't run into memory issues waiting for the entire training to complete.

### What are the 7 steps in SGD for machine learning?

Initialize weights, Predict, calculate loss, determine gradient, update parameters, repeat and stop.

### How do we initialize the weights in a model?

Randomly. There are other methods, but randomly is a good starting point.

### What is "loss"?

Loss is the function that tells us how well or how poorly our model predicted an output for a example.

### Why can't we always use a high learning rate?

The learning rate is what we use gently adjust the parameters. A high learning rate can cause our loss to jump around sporadically as we attempt to minimize it.

### What is a "gradient"?

The gradient of a function, denoted as follows, is the vector of partial derivatives with respect to all of the independent variables, aka, the parameters.

The _derivative_, it's a function that describes the slope of another function at a given point. It tells us how "quickly" a function changes at a certain input.

To calculate the partial derivative of a single parameter, you hold all other parameters constant. After computing all of the partial derivatives, they're collected into a vector call the gradient.

### Do you need to know how to calculate gradients yourself?

Nope. Thanks Pytorch!

### Why can't we use accuracy as a loss function?

Accuracy is for humans to consume. It tells us how well a model is at prediction examples that it has never seen before (in the validate set) overall. Accuracy isn't necessarily a function from which we can calculate a gradient/derivative in order update our weights. In the MNIST model in this chapter, a small nudge in a parameter won't necessarily effect accuracy, unless that small nudge changes a prediction from a `0` to a `1` or vice versa. 

### Draw the sigmoid function. What is special about its shape?

It looks like an S on it side with horizontal asymptotes a `y=0` and `y=-1`. The smooth curve makes it special because it helps us to gently calculate derivatives of our loss.

### What is the difference between loss and metric?

A we use a metric to determine human-interpretable accuracy, the model uses loss to determine how to update weights.

### What is the function to calculate new weights using a learning rate?

In this example: Stochastic Gradient Descent

### What does the DataLoader class do?

DataLoader will return an `(x, y)` tuple for our model, divide the data into training and validation sets, and create mini batches

### Write pseudo-code showing the basic steps taken each epoch for SGD.

```python
prediction = model(x, params)
loss = loss(prediction, label)
loss.backward()
for p in params:
    p.grad.data += lr * p.grad.data
    p.grad.data = None
```

### Create a function which, if passed two arguments [1,2,3,4] and 'abcd', returns [(1, 'a'), (2, 'b'), (3, 'c'), (4, 'd')]. What is special about that output data structure?

```python
def f(a, b): return list(zip(a, list(b)))
```

It returns a list of tuples.


### What does view do in PyTorch?

From the [docs](https://pytorch.org/docs/stable/tensor_view.html): 

PyTorch allows a tensor to be a View of an existing tensor. View tensor shares the same underlying data with its base tensor. Supporting View avoids explicit data copy, thus allows us to do fast and memory efficient reshaping, slicing and element-wise operations.

For example, to get a view of an existing tensor t, you can call t.view(...).

```python
>>> t = torch.rand(4, 4); t
tensor([[0.2108, 0.4824, 0.4418, 0.9436],
        [0.9554, 0.5866, 0.7631, 0.2809],
        [0.2934, 0.7608, 0.7741, 0.6948],
        [0.0813, 0.5682, 0.8023, 0.3858]])
>>> b = t.view(2, 8); b
tensor([[0.2108, 0.4824, 0.4418, 0.9436, 0.9554, 0.5866, 0.7631, 0.2809],
        [0.2934, 0.7608, 0.7741, 0.6948, 0.0813, 0.5682, 0.8023, 0.3858]])
>>> t.storage().data_ptr() == b.storage().data_ptr()  # `t` and `b` share the same underlying data.
True
# Modifying view tensor changes base tensor as well.
>>> b[0][0] = 3.14
>>> t[0][0]
tensor(3.14)
```

### What are the "bias" parameters in a neural network? Why do we need them?

> Bias terms are additional constants attached to neurons and added to the weighted input before the activation function is applied. Bias terms help models represent patterns that do not necessarily pass through the origin. For example, if all your features were 0, would your output also be zero? Is it possible there is some base value upon which your features have an effect? Bias terms typically accompany weights and must also be learned by your model. —[https://ml-cheatsheet.readthedocs.io/en/latest/nn_concepts.html?highlight=bias#bias](https://ml-cheatsheet.readthedocs.io/en/latest/nn_concepts.html?highlight=bias#bias)

### What does the @ operator do in python?

Matrix multiplication ( `*` is element-wise multiplication)

### What does the backward method do?

`loss.backward()` computes `dloss/dx` for every parameter `x` which has `requires_grad=True`. These are accumulated into `x.grad` for every parameter `x`. In pseudo-code:

```
x.grad += dloss/dx
```

[https://medium.com/@zhang_yang/how-pytorch-tensors-backward-accumulates-gradient-8d1bf675579b](https://medium.com/@zhang_yang/how-pytorch-tensors-backward-accumulates-gradient-8d1bf675579b)

### Why do we have to zero the gradients?

See link above, pytorch will _accumulate_ the gradient from all operations.

### What information do we have to pass to Learner?

The DataLoader that contains the data, the model, the optimization function (e.g. SGD), loss functions (e.g. MSE), and any metrics to print

```python
learn = Learner(dls,
                nn.Linear(28*28,1),
                opt_func=SGD,
                loss_func=mnist_loss,
                metrics=batch_accuracy)
```

### Show python or pseudo-code for the basic steps of a training loop.

```python
for _ in range(epoch):
    prediction = model(x, params)
    loss = loss(prediction, label)
    loss.backward()
    for p in params:
        p.grad.data += lr * p.grad.data
        p.grad.data = None
```

### What is "ReLU"? Draw a plot of it for values from -2 to +2.

A ReLU, or rectified linear unit, replaces every negative number with `0`

### What is an "activation function"?

I understand an activation function as being a non-linear layer in a neural network. This has the effect of allowing or preventing a certain "neuron" from activating depending on a threshold. For a ReLU, only positive values in a previous layer would be passed forward to the next layer. Similarly, a unit step function only passes values greater than `0` to the subsequent layers, but all positive values are passed on as `1`.

### What's the difference between F.relu and nn.ReLU?

`F.relu` is the function, `nn.ReLU` is the Pytorch module module.

### The universal approximation theorem shows that any function can be approximated as closely as needed using just one nonlinearity. So why do we normally use more?

Efficiency and performance. With deeper models, we don't need as many parameters. Smaller matrices with more layers > larger matrices with fewer layers.
