---
title: Evolutionary Algorithm for Low-Poly Image Reconstruction in Ruby
subtitle: Also an Introduction to the Petri Dish Gem
author: Thomas Countz
layout: post
featured: false
draft: true
tags: ["ruby", "generative art", "machine learning"]
---

In the field of computational generative creativity, genetic algorithms can prove to be a fascinating tool. Inspired by biological systems, they allow us to harness the power of evolution to generate unique and innovative results. One such creative use-case is the reconstruction of images in a low-polygon format. 

<div style="text-align:center">
  <img style="border: 1px solid gray; padding: 20px" src="/assets/images/low_poly_image/ruby_logo_result.png" />
  <figcaption>Result of over 2000 generations of evolution creating a low-poly representation of the Ruby logo.<i>You may need to squint to see it...</i></figcaption>
</div>

In this post, we'll be using the [petri_dish_lab](https://github.com/thomascountz/petri_dish) gem (which I may sometimes refer to as a framework) to reconstruct a black-and-white Ruby logo into a low-poly representation. The code for this blog post can be found as an example in the [/examples/low_poly_image_reconstruction](https://github.com/Thomascountz/petri_dish/tree/main/examples/low_poly_reconstruction) directory of the [Petri Dish](https://github.com/thomascountz/petri_dish) repository. 

<br /><br />

1. [Let's kick things off with a quick refresher on the theory of evolutionary algorithms](#evolutionary-algorithms),
2. [before we dive into the specifics of the problem at hand](#understanding-the-problem).
3. [We'll then do some data engineering, focusing on how we represent an individual image within our population](#member-representation),
4. [followed by a deep-dive into how we determine the fitness of each member](#fitness-function),
5. [and the mechanisms we'll use to evolve our population](#genetic-operators).
6. [And for the grand finale, we'll bring it all together and witness the algorithm and framework doing their magic](#putting-it-together)!
  

<br /><br />

# Evolutionary Algorithms

Evolutionary algorithms are optimization algorithms that "search" through a vast space of potential solutions. The goal of a search algorithm is to find a solution that satisfies some criteria, or _objective_. In our case, we want to find a set of polygon vertices and grayscale values that, when combined, approximate a given image.

At a high-level the way we'll accomplish this is by creating a bunch of images with random polygons. 

Then, pixel-by-pixel, we'll compare each of those images to the target image in order to determine how close they are to the target, i.e. their _fitness_. 

We'll then select _parent_ images based on their fitness and combine them to create a new _child_ image, perhaps with a few random _mutations_ (e.g. shifting of vertices or changes of color). 

This parent selection, child creation, and mutation repeats until we have enough new images to form a new population. 

If any of the new images meet the criteria, we're done! 

Otherwise, we'll repeat this process until we find an image that is close enough to the target.

An evolutionary algorithm configured in this way is called a _genetic algorithm_. There are many different types of evolutionary algorithms, but they all share the same basic structure:

1. Create a population of random solutions
2. Evaluate the fitness of each solution
3. Select parents based on their fitness
4. Combine parents to create new solutions
5. Repeat until a solution is found

The [Petri Dish](https://github.com/thomascountz/petri_dish) framework is a Ruby gem that implements this structure and allows us to focus on the problem we're trying to solve rather than the implementation of the algorithm. This is because, as we'll see, the specifics of an evolutionary algorithm is highly dependent on the problem we're trying to solve.

The Petri Dish framework works by exposing a [`PetriDish::Configuration#configure`](https://github.com/Thomascountz/petri_dish/blob/133be9efea42e7e3f62e01cd92a77ba03425afa4/lib/petri_dish/configuration.rb#L18-L22) method that takes a block of configuration options. The core configuration options that we'll look at in this post are:

| Parameter                    | Description                                                                                         |
| ---------------------------- | --------------------------------------------------------------------------------------------------- |
| `fitness_function`           | A function used to calculate the fitness of an individual                                           |
| `parents_selection_function` | A function used to select parents for crossover                                                     |
| `crossover_function`         | A function used to perform crossover between two parents                                            |
| `mutation_function`          | A function used to mutate the genes of an individual                                                |
| `mutation_rate`              | The chance that a gene will change during mutation                                                  |
| `elitism_rate`               | The proportion of the population preserved through elitism                                          |
| `max_generations`            | The maximum number of generations to run the evolution for                                          |
| `end_condition_function`     | A function that determines whether the evolution process should stop premature of `max_generations` |

We'll take a look at each of these functions in detail later, but for now, let's see how we can use the framework to solve our problem.

# Understanding the Problem

In order to develop an evolutionary algorithm, we must first define the problem we are trying to solve. In our case, we are trying to reconstruct a given image in a low-polygon format. This means that we are trying to **find a set of polygons that, when combined, approximate the given image**. That is our _objective_.

The polygons, in our case are triangles, and can be defined by three vertices. **Each vertex can be encoded as an `(x, y)` coordinate and an 8-bit (`0-255`) grayscale value, together called a `Point`.** This is all the information we need create a low-poly image. These are our _decision variables_, or _genes_ of our algorithm. Each member of the population will have a distinct set of genes and the algorithm will search for the member of the population whose genes are the most _fit_, i.e. that best approximates the target image.

> ☝️ **Why Points instead of Triangles?**\
> As we'll see later, we'll use what's called [_Delaunay triangulation_](https://en.wikipedia.org/wiki/Delaunay_triangulation) to create triangles from these points, rather than define triangles directly. (I tried to define triangles directly before I knew about Delaunay triangulation. It was a mess: triangles overlapped everywhere and therefore the resulting images were not in the traditional low-poly style).

Lastly, we need to define our _constraints_, or the boundaries of the search space. In our case, mostly due to the arbitrary limit of my laptop's processing power, **we will limit the height and width of the image to 100x100 pixels and the color space to grayscale.**

With our objective, decision variables, and constraints defined, we can codify the representation of each image, how we know when we've found a good solution, and how we step through the vast space of potential solutions.

# Member Representation

Evolutionary algorithms are generic in the sense that they can be applied to a wide variety of problems. Therefore, we must encode our problem into a format that can be understood by the algorithm.

We need to encode 1) the input (target) image, 2) the _genes_ of each member of the population, and 3) the output (reconstructed) image. 

For the input and output images, we'll use the [`RMagick`](https://github.com/rmagick/rmagick) library which provides a Ruby interface to the [ImageMagick](https://imagemagick.org/) image processing library. 

Starting with the input image, we can import it into our program, crop it to a square, resize it to our desired dimensions, and convert it to grayscale. We'll also save the image to a file for later comparison.

```ruby
require 'rmagick'

def import_target_image(input_path, output_path)
  image = Magick::Image.read(input_path).first

  # Calculate crop size and coordinates for center crop
  crop_size = [image.columns, image.rows].min
  crop_x = (image.columns - crop_size) / 2
  crop_y = (image.rows - crop_size) / 2

  image
    .crop(crop_x, crop_y, crop_size, crop_size)
    .resize(IMAGE_HEIGHT_PX, IMAGE_WIDTH_PX)
    .quantize(256, Magick::GRAYColorspace)
    .write(output_path)

  image
end
```

For the genes of each member (potential solution), we'll define a `Point` Struct to hold the `(x, y)` coordinates and a grayscale value of each vertex of a polygon.

```ruby
  Point = Struct.new(:x, :y, :grayscale)
```
> 🌈 **Why does a Point have color?**\
> Notice here that a the color value is defined on the _point_ and not on a triangle itself. This is because, as we're about to see, we aren't sure which points will be connected together to create any particular triangle. Therefore, for any given triangle, we'll average the grayscale values of its three points together to determine the fill color.

To turn these points into an image, we'll need to use a technique called [_Delaunay triangulation_](https://en.wikipedia.org/wiki/Delaunay_triangulation). This technique takes a set of points and creates a set of triangles such that no point is inside the circumcircle of any triangle, i.e. no triangle overlaps another. The [`delaunator`](https://github.com/hendrixfan/delaunator-ruby/tree/master) gem is a Ruby library that performs Delaunay triangulation, so we'll use that because the math is... a bit beyond me. 

When we're ready to create an image from our points, we'll initialize a new `RMagick::Image` object, perform the Delaunay triangulation, determine the grayscale fill value, and draw each triangle onto the image.

```ruby
require 'petri_dish'
require 'delaunator'

def member_to_image(member, width, height)
  image = Magick::Image.new(width, height) { |options| options.background_color = "white" }
  draw = Magick::Draw.new

  # Perform Delaunay triangulation on the points
  # Delaunator.triangulate accepts a nested array of [[x1, y1], [xN, yN]]
  # coordinates and returns an array of triangle vertex indices where each
  # group of three numbers forms a triangle
  triangles = Delaunator.triangulate(member.genes.map { |point| [point.x, point.y] })

  triangles.each_slice(3) do |i, j, k|
    # Get the vertices of the triangle
    triangle_points = member.genes.values_at(i, j, k)

    # Take the average color from all three points
    color = triangle_points.map(&:grayscale).sum / 3
    draw.fill("rgb(#{color}, #{color}, #{color})")

    # RMagick::Image#draw takes an array of vertices in the form [x1, y1,..., xN, yN]
    vertices = triangle_points.map { |point| [point.x, point.y] }
    draw.polygon(*vertices.flatten)
  end

  draw.draw(image)
  image
end
```

The important part here is that we are able to convert a member of the population into an `RMagick::Image` object that can be compared to the target `RMagic::Image`. The intermediate member representation of an Array of `Point`-s, called `Member#genes`, is *calculable* and *evolvable* by the Petri Dish framework.

The Petri Dish framework gives us a `Member` class that can hold onto the `genes` Array. These `genes` are then directly exposed via the `PetriDish::Memeber#genes` method.

```ruby
module PetriDish
  class Member
    attr_reader :genes

    def initialize(genes:, fitness_function:)
      @fitness_function = fitness_function
      @genes = genes
    end

    def fitness
      @fitness ||= @fitness_function.call(self)
    end

    def to_s
      genes.join("")
    end
  end
end
```

The initializer also accepts a `fitness_function` which is use to evaluate the fitness of a member.

# Fitness Function

```ruby
configuration.fitness_function = calculate_fitness(target_image)
```

All of the `Point`s-to-`Image` conversion is in support of the fitness function (as well as for us to actually be able to see the image). The fitness function is a function that takes a `Member` and returns a number that represents how well that member solves the problem. In our case, we want to know how well a member approximates the target image. 

Modeling a fitness function to map to the search space is often the most difficult part of developing an evolutionary algorithm. It's also the most important part because it's what the algorithm uses to determine which members are better than others. Two key qualities of a fitness function are *determinism* and *discrimination*.

Deterministic means that given the same `Member`, the fitness function should always return the same fitness score. This is because the fitness of a member may be evaluated multiple times during the evolutionary process, and inconsistent results could lead to unpredictable behavior.

Discriminative means that the fitness function should be able to discriminate between different members of the population. That is, members with different genes should have different fitness scores. Although fitness function do not have to be strictly discriminative, if many members have the same fitness score, the evolutionary algorithm may have a harder time deciding which members are better.

Lucky for us, the `RMagick` library provides an [`Image#difference`](https://rmagick.github.io/image1.html#distortion_channel) method that fits the bill. `Image#difference` compares two images and returns three numbers that represent how different they are: `mean_erorr_per_pixel`, `normalized_mean_error`, and `normalized_maximum_error`. We'll use the `mean_error_per_pixel` to calculate our fitness score.

```ruby
require 'petri_dish'
require 'rmagick'

def calculate_fitness(target_image)
  ->(member) do
    member_image = member_to_image(member, IMAGE_WIDTH_PX, IMAGE_HEIGHT_PX)
    # Difference is a tuple of [mean_error_per_pixel, normalized_mean_error, normalized_maximum_error]
    # Square the mean_error_per_pixel to make the fitness score more sensitive to small changes
    # Return the inverse of the mean_error_per_pixel to make smaller errors have larger fitness scores
    1 / (target_image.difference(member_image)[0]**2)
  end
end
```

The fitness function is a lambda that takes a `Member` and returns a number. The number is the inverse of the mean error per pixel between the target image and the image generated from the member, squared. This means that the higher the fitness score, the better the member approximates the target image.

> 2️⃣ **Why squared?**\
> Squaring the mean error per pixel means that the fitness score will increase exponentially as the member gets closer to the target image. This is a good thing because it means that as we get closer to the target, the algorithm will be more sensitive to small changes in the member's genes. Other fitness functions may be directly linear, and others still may require more complex transformations.

> 🙃 **Why the inverse?**\
> The mean error per pixel measures the _error_ of a solution, which we want to _minimize_. However, since evolutionary algorithms are designed to _maximize_ fitness, we take the inverse of the error. As a result, solutions with smaller errors (which are better) will have larger fitness values, and the algorithm will correctly try to maximize fitness, and therefore minimize error.

Lastly, we define `#calculate_fitness` as a lambda because the Petri Dish framework requires the `fitness_function` to respond to `#call`. The framework will call this lambda via the `#fitness` method on `Member` in order to memoize and return the fitness score. We use a closure here so that the `target_image` is available to the lambda when it's called.

> 📫 **Closures**\
> _Closures_ are a powerful feature of Ruby and other languages. They allow us to define a function that can be called later, but that also has access to the variables that were in scope when the function was defined. It's like putting a note inside an envelope for the function to open later. In our case, we want to define a function that can be called later by the Petri Dish framework, but that also has access to the `target_image` that we defined earlier.


Now that we have a way to represent a member of the population and a way to evaluate the fitness of a member, we can start to evolve the population by defining the evolutionary operators.

# Genetic Operators

The genetic operators are the functions that we use to evolve the population generation after generation—they are what allow the algorithm to navigate the vast search space of potential solutions.

The operators we'll take a look at are grouped by _selection_, _crossover_, _mutation_, and _replacement_.

## Parent Selection Function

```ruby
configuration.parents_selection_function = roulette_wheel_parent_selection_function
```

Selection is the process of choosing which members of the population are the most fit and therefore should be used as _parents_ to create the next generation of _children_. There are many different selection strategies, but for our task, we'll use one called _fitness proportionate selection_.

Also called _roulette wheel selection_ or _stochastic acceptance_, fitness proportionate selection works by assigning each member a weighted probability of being selected as a parent, and then randomly selects parents based on those probabilities. The weighted probability assigned to each member is proportional to that member's fitness score, which means that members with higher fitness scores are more likely to be selected.

For example, say we have the following `Member`-s with the following fitness scores:

```ruby
population = [
  Member.new(genes: [1, 2, 3], fitness_function: ->(_member) { 2 }),
  Member.new(genes: [4, 5, 6], fitness_function: ->(_member) { 3 }),
  Member.new(genes: [7, 8, 9], fitness_function: ->(_member) { 5 }),
]
```

If we assign a weighted probability to each member based on the total fitness (`member_fitness / population_fitness`), we would get the following results:

```ruby
population = [
  member: Member.new(genes: [1, 2, 3], fitness_function: ->(_member) { 0.1 }), # => weight: 0.2
  member: Member.new(genes: [4, 5, 6], fitness_function: ->(_member) { 0.2 }), # => weight: 0.3
  member: Member.new(genes: [7, 8, 9], fitness_function: ->(_member) { 0.3 })  # => weight: 0.5
]
```

Then, we can _randomly_ select a member based on these probabilities. For example, if we were to select multiple members using these weighted probabilities, we would expect to get the first member, `population[0]`, 20% of the time, the second member, `population[1]`, 30% of the time, and the third member, `population[2]`, 50% of the time.

Here's what the `roulette_wheel_parent_selection_function` looks like for selecting two parents:

```ruby
  def roulette_wheel_parent_selection_function
    ->(members) do
      population_fitness = members.sum(&:fitness)
      members.max_by(2) do |member|
        weighted_fitness = member.fitness / population_fitness.to_f
        rand**(1.0 / weighted_fitness)
      end
    end
  end
  ```

Here, we first calculate the total fitness for the population, then we select the two members with the highest weighted fitness. The weighted fitness is calculated by dividing the member's fitness by the total fitness. Then, we raise a random number between 0 and 1 to the inverse of the weighted fitness. This means that members with higher fitness scores will have a higher probability of being selected. 

The result of all of this is like spinning a roulette wheel where the size of each slice is proportional to the member's fitness. The higher the fitness, the larger the slice, and the more likely the member is to be selected.

There are many other selection methods, like simply selecting the fittest members (elite selection) or by first choosing a random subset of the population and then choosing the fittest amongst those (tournament selection). 

The benefit of fitness proportional selection is that it allows for a balance between _exploration_ (trying new things) and _exploitation_ (using what we know works). This is because members with lower fitness scores still have a chance of being selected, but members with higher fitness scores are more likely to be selected.

> 👨‍👨‍👦 **Multiple Parents**\
> Although most implementations of evolutionary algorithms that I've seen select two parents, it's possible to select more than two. In fact, the Petri Dish framework allows you for any number of parents to be inside the Array returned by the selection function.


## Crossover Function

```ruby
configuration.crossover_function = random_midpoint_crossover_function
```

In biology, crossover is when paired chromosomes from each parent swap segments of their DNA. This creates new combinations of genes, leading to genetic diversity in offspring. In evolutionary algorithms, crossover is the process of combining the genes of two parents to create a new child.

After selecting parents, their genes, an Array of `Point`-s, are combined to create a new `Member`. There are many different ways to combine the genes of two parents, but for our task, we'll use a method called _random midpoint crossover_.

Random midpoint crossover starts by selecting a random point, called the _midpoint_ within the genes of the first parent. Then genes of the child `Member` are then the genes from the start of the first parent's genes up to the midpoint, followed by the genes from the midpoint to the end of the second parent's genes.

For example, say we have two parents with the following genes:

```ruby
parent_1 = Member.new(
  genes: [
    Point.new(1, 2, 120),
    Point.new(4, 5, 211),
    Point.new(7, 8, 9),
  ],
  # fitness_function: ...
)
parent_2 = Member.new(
  genes: [
    Point.new(10, 11, 24),
    Point.new(13, 14, 15),
    Point.new(16, 17, 88),
  ],
  # fitness_function: ...
)
```

If we were to perform random midpoint crossover on these parents, and the `midpoint = 1`, we would get the following child:

```ruby
child = Member.new(
  genes: [
    Point.new(1, 2, 120),
    Point.new(4, 5, 211),
    Point.new(16, 17, 88),
  ],
  # fitness_function: ...
)
```

Here's our `random_midpoint_crossover_function` implementation for combining two parents:

```ruby
  def random_midpoint_crossover_function(configuration)
    ->(parents) do
      midpoint = rand(parents[0].genes.length)
      PetriDish::Member.new(genes: parents[0].genes[0...midpoint] + parents[1].genes[midpoint..], fitness_function: configuration.fitness_function)
    end
  end
```

Note again, our function returns a lambda, as required by the Petri Dish framework. The lambda takes an Array of parents and returns a new `Member` with the combined genes of the parents, while also passing along the `fitness_function` from the configuration. The `configuration` object is captured by the closure in order to pass along the `fitness_function` to the new `Member`.

Other crossover methods include _uniform crossover_, where each gene is randomly selected from either parent, and _majority rule crossover_. Majority rule crossover works well for more than two parents. It works by having each gene of the offspring determined by a majority vote among the parents. If the parents have equal votes, one parent is chosen randomly to determine the gene.

Random midpoint crossover is a good choice for starting out for its simplicity, but it may be worth experimenting with other crossover methods to see if they work better for our problem. (In fact, its possible to use one genetic algorithm to optimize the parameters of another genetic algorithm, but that's a topic for another day...).

> 👩‍🔬 **Meta Experimentation**\
> This type of meta experimentation is akin to hyperparameter tuning in machine learning. A core design philosophy of the Petri Dish framework is to make it easy to experiment with different configurations in this way. By passing in different functions for the genetic operators, we can easily experiment with different configurations and observe which ones work best.

## Mutation Function

```ruby
configuration.mutation_function = nudge_mutation_function
configuration.mutation_rate = 0.1
```
Mutation is the process of randomly changing the genes of a child member after crossover. Combining the most-fit parents can get us towards a great solution, however mutation is done to introduce new genetic material into the population in order to prevent the algorithm from getting stuck in a local maximum. There are many different ways to mutate a member, but for our task, we'll use, what I call, _nudge mutation_.

> 🧬 **Why mutate at all?**\
> Mutation is not strictly necessary for an evolutionary algorithm to work. However, mutation increases diversity and diversity is what allows the algorithm to explore the search space more thoroughly. Without mutation, the algorithm may get stuck in a local maximum, i.e. unable to find a better solution. Mutation allows the algorithm to escape this local maximum and continue searching for a better solution.

If we think back to our genes as an Array of `Point`-s, then nudge mutation is the process of randomly moving each point's position and grayscale value a small amount. This is done by adding a random number between `-5` and `5` to the `x` and `y` coordinates of each point. The grayscale value is also mutated by adding a random number between `-5` and `5`, but `clamp`-ed between `0..255` (i.e. valid grayscale values).

If we implemented this as a lambda for the Petri Dish `mutation_function` configuration (RBS type `Proc[Member, Member]`), it might look something like this:

```ruby
  def nudge_mutation_function(configuration)
    ->(member) do
      mutated_genes = member.genes.dup.map do |gene|
          Point.new(
            gene.x + rand(-5..5),
            gene.y + rand(-5..5),
            (gene.grayscale + rand(-5..5)).clamp(0, 255)
          )
      end
      PetriDish::Member.new(genes: mutated_genes, fitness_function: configuration.fitness_function)
    end
  end
```

Then, if we have a child member with the following genes:

```ruby
member = Member.new(
  genes: [
    Point.new(5, 5, 120),
    Point.new(10, 20, 240),
  ],
  # fitness_function: ...
)
```

We might expect to get something like the following (the specific numbers aren't important, but we see that the `x` and `y` coordinates and the grayscale values have changed `+/- 5`):

```ruby
member = Member.new(
  genes: [
    Point.new(1, 8, 115),
    Point.new(9, 20, 238),
  ],
  # fitness_function: ...
)
```

However, don't want to mutate every gene of a child; we want to preserve qualities from the parents. Therefore, we use a _mutation rate_ to determine the probability that any particular gene will be mutated. For example, if the mutation rate is `0.1`, then there is a 10% chance that a gene will be mutated.

If we add the concept of a mutation rate to our mutation function, we get this:

```ruby
def nudge_mutation_function(configuration)
  ->(member) do
    mutated_genes = member.genes.dup.map do |gene|
      if rand < configuration.mutation_rate
        Point.new(
          gene.x + rand(-5..5),
          gene.y + rand(-5..5),
          (gene.grayscale + rand(-5..5)).clamp(0, 255)
        )
      else
        gene
      end
    end
    PetriDish::Member.new(genes: mutated_genes, fitness_function: configuration.fitness_function)
  end
end
```

Here, we use the `configuration.mutation_rate` to determine whether or not to mutate each gene. If the random number is less than the mutation rate, we mutate the gene, otherwise, copy it over to the new `Member` as-is.

> 📈 **Determining the mutation rate**\
> The mutation rate is a hyperparameter that can be tuned to improve the performance of the algorithm. A higher mutation rate will increase diversity, but it may also cause the algorithm to take longer to converge. A lower mutation rate will decrease diversity, but it may also cause the algorithm to get stuck in a local maximum. The mutation rate is often a good hyperparameter to tune when trying to improve the performance of an evolutionary algorithm. (`0.1` is somewhat of a high mutation rate, but as we'll see later, this value was chosen because it worked well for my particular configuration of the problem).

Other common types of mutation strategies include _swap mutation_, where two genes are randomly swapped, and _scramble mutation_, where a random subset of genes are randomly shuffled. Like all other genetic operators, the best strategy for the problem at hand is highly dependent on the problem itself and is often worth experimenting with. In our case, the mutation function implementation was developed to represent the idea of nudging around the points of a polygon until the resulting image looks like the target image.

> 🪲 **Point jitter??**\
> You may see that in the [actual implementation](https://github.com/Thomascountz/petri_dish/blob/133be9efea42e7e3f62e01cd92a77ba03425afa4/examples/low_poly_reconstruction/low_poly_reconstruction.rb#L115-L130) of this method, I've added a `point_jitter` of `rand(-0.0001..0.0001)` to each `x` and `y` of `Point`. This because the particular implementation of the Delaunay algorithm would fall into a divide-by-zero error if all of the points were collinear (on exactly on the same line). This is a good example of how reality is often messier than theory, and how we must adapt our models and implementation to the problem at hand.

Now that we have a way to select parents, combine their genes, and mutate the resulting child, we can start to evolve the population. The last step is to define how we'll replace the old population with the new population.

## Replacement

```ruby
configuration.elitism_rate = 0.1
```

In the most simple case, we can replace the entire population with the new population, sometimes called _generational replacement_. This often works well, but it can sometimes cause _too much_ diversity, which can cause the algorithm to take longer to converge as some of the most-fit members are lost. To prevent this, we can use a technique called _elitism_.

Elitism, which I personally like to call _grandparenting_, is the process of preserving the fittest members of the population from one generation to the next. This is done by taking the top `n` members of the population and adding them to the new population. The rest of the new population is filled with the children of the parents.

In the Petri Dish framework, we tune this parameter using the `elitism_rate` configuration. This is the proportion of the population that is preserved through elitism. For example, if the elitism rate is `0.1`, then the top 10% of the population will be preserved through elitism.

Other replacement strategies include _steady-state replacement_, where only a single member of the population is replaced with a child, and _age-based replacement_, where the oldest members of the population are replaced with children.

## End Condition

```ruby
configuration.max_generations = 2500
configuration.end_condition_function = nil
```

Lastly, we need to define when the algorithm should stop. The two most common end conditions are when a member of the population meets the criteria, or when a certain number of generations have passed. We'll use the latter.

An `end_condition_function` can otherwise be used to determine if any of the members of the population meets a particular criteria. For example, if we were trying to find a member of the population that had a fitness score of `1.0`, we could use an `end_condition_function`. Alternatively, we could run the algorithm for a given amount of wall time, or until the rate of improvement drops below a certain threshold.

In our case, we'll use the `max_generations` configuration to determine when the algorithm should stop. This is the maximum number of generations that the algorithm will run for, regardless of the fitness of the members of the population. I have found that `2500` generations is enough to get a good approximation of the target image, but not so many that it takes too long to run.

We now have all of the pieces we need to put together our evolutionary algorithm. Let's see how it all works!

# Putting it Together

## Final Configuration

The following is the configuration from the [actual implementation](https://github.com/Thomascountz/petri_dish/blob/133be9efea42e7e3f62e01cd92a77ba03425afa4/examples/low_poly_reconstruction/low_poly_reconstruction.rb#L42-L56) and contains all of the pieces we've discussed so far, with the addition of a few callbacks that the framework provides.

```ruby
def configuration
  PetriDish::Configuration.configure do |config|
    config.population_size = 50
    config.mutation_rate = 0.1
    config.elitism_rate = 0.1
    config.max_generations = 2500
    config.fitness_function = calculate_fitness(target_image)
    config.parents_selection_function = roulette_wheel_parent_selection_function
    config.crossover_function = random_midpoint_crossover_function(config)
    config.mutation_function = nudge_mutation_function(config)
    config.highest_fitness_callback = ->(member) { save_image(member_to_image(member, IMAGE_WIDTH_PX, IMAGE_HEIGHT_PX)) }
    config.generation_start_callback = ->(current_generation) { generation_start_callback(current_generation) }
    config.end_condition_function = ->(_member) { false } # This will be assigned to `nil` in an update
  end
end
```

The `highest_fitness_callback` is invoked when a member with the highest fitness seen so far is found. What that happens, we save the image to a file so that we can see the progress of the algorithm.

The `generation_start_callback` is invoked at the start of each generation. We use this to keep track of the progress of the algorithm to do things like name the output images.

The final piece of the configuration we haven't talked about is the `population_size`. This is the number of `Member`-s per generation, and like all other pieces of configuration, is a hyperparameter that should be tuned to improve the performance of the algorithm. A larger population size can increase diversity, but it may also cause the algorithm to take longer to converge. A smaller population size can decrease diversity, but can be aided with a higher mutation rate and maximum number of generations, as we've done here.


## Initial Results

<div style="text-align:center;margin-bottom: 50px;">
  <img style="border: 1px solid gray; padding: 20px" src="/assets/images/low_poly_image/ruby_logo_result.png" />
  <figcaption>Result of over 2000 generations of evolution creating a low-poly representation of the Ruby logo.<i>You may need to squint to see it...</i></figcaption>
</div>

<div style="text-align:center">
  <img style="border: 1px solid gray; padding: 20px" src="/assets/images/low_poly_image/montage.png" />
  <figcaption>Output of the <code>highest_fitness_callback</code> calls show a progressively more refined low-poly representation</figcaption>
</div>

Running with the above configuration over 2500 generations, we get the following output, we get a close approximation of the target image: the Ruby logo.

## 