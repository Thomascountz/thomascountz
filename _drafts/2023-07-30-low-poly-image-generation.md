---
title: Evolutionary Algorithm for Low-Poly Image Reconstruction in Ruby
subtitle: Also an Introduction to the Petri Dish Gem
author: Thomas Countz
layout: post
featured: false
draft: true
tags: ["ruby", "generative art", "machine learning"]
---

Inspired by biological systems, evolutionary algorithms model the patterns of multi-generational evolution in order to unearth unique ideas. They work by generating a vast number of potential solutions to a particular problem and then pitting them against each other in a process akin natural selection: only the fittest survive. In this way, evolutionary algorithms are able to navigate large ambiguous search spaces in order to find solutions to problems that may be difficult or inefficient to solve using other methods.

These algorithms are used for a wide variety of tasks: from optimizing neural network parameters, evolving mechanical structures, simulating protein folding, and even generating art! 

Today, we will use one such algorithm to create a low-poly version of the Ruby logo.

<div style="text-align:center">
  <img style="border: 1px solid gray; padding: 20px" src="/assets/images/low_poly_image_generation/ruby_logo_result.png" />
  <figcaption>Result of 5000 generations of evolving a low-poly representation of the Ruby logo.</figcaption>
</div>

In this post, we're going to be using the [petri_dish_lab](https://github.com/thomascountz/petri_dish) gem for the task of _image reconstruction_. Image reconstruction is a great example to use because we'll be able to visualize the evolutionary process working over time.

We'll begin by going over what an evolutionary algorithm is and how it works. Then, we'll take a look at the Petri Dish framework and how we can use it to implement an evolutionary algorithm. Next, we'll define the objective of our image reconstruction problem and how we can represent it in code. Then, we'll define the genetic operators that we'll use to evolve the population. Finally, we'll put it all together and see the results!

> 🧑‍💻 [**Code Here**](https://github.com/thomascountz/petri_dish)\
> The complete code for this blog post can be found as an example in the [`examples/low_poly_image_reconstruction`](https://github.com/Thomascountz/petri_dish/tree/main/examples/low_poly_reconstruction) directory of the [Petri Dish](https://github.com/thomascountz/petri_dish) repository. I recommend following along with the code as you read this post.

<br />

# Table of Contents <!-- omit in toc -->

- [Evolutionary Algorithm Crash Course](#evolutionary-algorithm-crash-course)
  - [The Petri Dish Framework](#the-petri-dish-framework)
- [Understanding the Objective](#understanding-the-objective)
- [Member Representation](#member-representation)
  - [Input _Target_ Image](#input-target-image)
  - [Member Genes](#member-genes)
  - [_Reconstructed_ Output Image](#reconstructed-output-image)
- [Fitness Function](#fitness-function)
- [Genetic Operators](#genetic-operators)
  - [Parent Selection Function](#parent-selection-function)
  - [Crossover Function](#crossover-function)
  - [Mutation Function](#mutation-function)
  - [Replacement](#replacement)
  - [End Condition](#end-condition)
- [Putting it Together](#putting-it-together)
  - [Final Configuration](#final-configuration)
- [Results](#results)
  - [Subjective Results](#subjective-results)
  - [Notes](#notes)


<br />

# Evolutionary Algorithm Crash Course

Evolutionary algorithms are optimization algorithms that "search" through an expansive space of potential solutions. The goal of a search algorithm is to find a solution that satisfies some criteria, or _objective_. Evolutionary algorithms are particularly good in cases where we want a solution that is "good enough," rather than an absolute optimum. In our case, we want to find a set of polygon vertices and grayscale values that, when combined, approximate a given image. For this usecase, there's no one "best" solution, so evolutionary algorithms are a good fit.

The image reconstruction process begins by creating a bunch of images with random polygons. We're going to use triangles, but we could technically use any shape, and we'll stick to grayscale colors in order to make the problem a bit simpler. This random set of images is called the _population_, and each image is called a _member_ of the population.

Once we have a bunch of random guesses, we compare each member to the target image, pixel-by-pixel, to determine their likeness to the target. This _measure of likeness_ is what we refer to as their _fitness_, and will be determined by how close each pixel is to the correct grayscale value.

Based on their fitness, _parent_ members are then chosen and combined to create a new _child_ member in a process called _crossover_. The way we select and crossover parent members is by using _selection_ and _crossover_ functions, which we'll go into more detail about later along with _mutation_ functions, which mirrors the biological process of genetic mutation by injecting random changes into the child member. Together, these functions are called the _genetic operators_. The exact implementation of these operators is perhaps the most important part of developing an evolutionary algorithm, and we'll spend a lot of time on them later. If you're familiar with machine learning, you can think of the genetic operators as _hyperparameters_.

And, just like in biological systems, the process of parent selection, child creation, and mutation repeats and repeats until we have enough new members to fill a new _population_. If any of the new members meet the criteria, we're done! Otherwise, we'll repeat this entire process, known as a _generation_, until we find a member that meets the objective, or we otherwise get close enough.

An evolutionary algorithm configured in this way is called a _genetic algorithm_. There are other types of evolutionary algorithms, but they all share a similar recursive structure, shown here in pseudocode:


```ruby
def run(population)
  # If population is empty, create a new population
  population = POPULATION_SIZE.times.map { create_random_member } if population.empty?
  
  # Select parents based on their fitness
  parents = select_parents(population)

  # Create a new population by combining parents and applying mutations
  new_population = population.size.times.map do
    child = combine(parents)
    apply_mutation(child)
  end

  # Evaluate the fitness of each member in the new population
  new_population.each { |member| calculate_fitness(member) }

  # If the objective is met, stop
  return new_population if is_objective_met?(new_population)

  # If not, go to step 2 by running the method recursively with the new population
  run(new_population)
end
```

## The Petri Dish Framework

The [Petri Dish](https://github.com/thomascountz/petri_dish) framework is a Ruby gem that implements the evolutionary algorithm structure for us in the `PetriDish::World.run` method. We "only" need to supply the members, how to evaluate their fitness, the genetic operators, and when to stop. This is because, as we'll see, the specifics of an evolutionary algorithm are highly dependent on the problem we're trying to solve, but the underlying structure is always the same.

Here's what a stripped down version of what the `PetriDish::World.run` method looks like. See if you can spot the similarities to the pseudocode above:

```ruby
module PetriDish
  class World
    class << self
      attr_accessor :metadata
      attr_reader :configuration, :end_condition_reached

      def run(
        members:,
        configuration: Configuration.new,
        metadata: Metadata.new
      )
        end_condition_reached = false
        max_generation_reached = false

        max_generation_reached = metadata.generation_count >= configuration.max_generations

        new_members = (configuration.population_size).times.map do
          parents = configuration.parents_selection_function.call(members)
          child_member = configuration.crossover_function.call(parents)
          configuration.mutation_function.call(child_member).tap do |mutated_child|
            end_condition_reached = configuration.end_condition_function.call(mutated_child)
          end
        end

        metadata.increment_generation

        unless end_condition_reached || max_generation_reached
          run(members: new_members, configuration: configuration, metadata: metadata)
        end
      end
    end
  end
end
```

The `PetriDish::World.run` method accepts a `members` Array, which contains the evolving population; a `configuration` object, which holds the user-defined genetic operators and other configuration options; and an internally used `metadata` object, which holds information about the current state of the algorithm, like the current generation number.

The Petri Dish framework exposes the [`PetriDish::Configuration#configure`](https://github.com/Thomascountz/petri_dish/blob/133be9efea42e7e3f62e01cd92a77ba03425afa4/lib/petri_dish/configuration.rb#L18-L22) method which takes a block of configuration options. 

The core configuration options that we're interested in for this post are:

| Parameter                    | Description                                                                                         |
| ---------------------------- | --------------------------------------------------------------------------------------------------- |
| `fitness_function`           | A function used to calculate the fitness of an individual                                           |
| `parents_selection_function` | A function used to select parents for crossover                                                     |
| `crossover_function`         | A function used to perform crossover between two parents                                            |
| `mutation_function`          | A function used to mutate the genes of an individual                                                |
| `mutation_rate`              | The chance that a gene will change during mutation                                                  |
| `max_generations`            | The maximum number of generations to run the evolution for                                          |
| `end_condition_function`     | A function that determines whether the evolution process should stop premature of `max_generations` |

We'll take a look at each of these functions in detail later, but for now, let's see how we can use the framework to evolve an image.

# Understanding the Objective

In order to develop an evolutionary algorithm, we must first define the objective we are trying to reach. As mentioned earlier, evolutionary algorithms work best when we define a criteria to aim towards, versus a discrete target. In our case, we are trying to replicate a given grayscale image using triangles. If we break this down in terms of drawing polygons, we want to **find a set of triangles that, when drawn together, approximate the given image**. That is our _objective_.

We'll define the triangles by their three vertices. **Each vertex can be encoded as an `(x,y)` coordinate and a grayscale value.** These are our _decision variables_. 

A series of these three-vertices-and-a-grayscale-value groupings is all the information we need create a low-poly image. We'll call these groupings "points" and an Array of them will represent each members' _genes_. Each member of the population will have a distinct set of these points and the algorithm will optimize for a member whose points, or genes, are more _fit_.

Note here that we don't necessarily know what the _most_ fit member would look before the algorithm begins searching. The algorithm only knows when a member is more fit—it approximates the target image better—than all other members seen thus far. The algorithm is searching for _a_ solution, not a specific solution.

> ☝️ **Why Points instead of Triangles?**\
> As we'll see later, we'll be using what's called [_Delaunay triangulation_](https://en.wikipedia.org/wiki/Delaunay_triangulation) to create triangles from a member's points/genes, rather than define triangles directly. Evolving points is a b/it simpler than evolving triangles, and it also allows us to use the same algorithm to evolve other shapes, like squares or circles.

Lastly, we need to define our _constraints_, or the boundaries of the search space. In our case (mostly due to the arbitrary limit of my laptop's processing power), **we will limit the height and width of the image to 100x100 pixels and the color space to 8-bit grayscale**. Independently, **we will also limit each members' genes to be 100 points**. 

> 🗺️ **Quantifying the Search Space**\
> With each point each having an `(x,y)` coordinate range of `(0..100, 0..100)` and a grayscale value range of `0..255`, each point can be in one of `101 * 101 * 256 = 2,626,816` possible states. And, since each member has 100 of these as its genes, this leads to a search space of `(101 * 101 * 256)**100` dimensions, which is an enormously large, but in practice, quite small for an evolutionary algorithm.

Now we have our objective: we want to find a set of 100 points, called genes, each with an `(x,y)` coordinate and a grayscale value, that when used to create triangles, approximate a given image. We also know the constraints of the problem: the image is 100x100 pixels and the grayscale values are 8-bit. And finally, we know that the search space is enormous... 

However, we aren't intimidated because we're going to use an evolutionary algorithm to search it for us.

# Member Representation

Evolutionary algorithms are generic in the sense that they can be applied to a wide variety of problems. Therefore, just as we would for a neural network, we must engineer, or encode, our problem into a format that can be understood by the algorithm's architecture.

We need to encode:
   1. [The input _target_ image](#input-target-image), 
   2. [The _genes_ of each member of the population](#member-genes), and
   3. [The _reconstructed_ output image](#reconstructed-output-image). 

## Input _Target_ Image

For both the input and output images, we'll use the [`Magick`](https://github.com/rmagick/rmagick) gem which provides a Ruby interface to the [ImageMagick](https://imagemagick.org/) image processing library. 

Starting with an input image path, we can read the image into memory, center crop it to a 100x100 pixel square, and then convert it to grayscale. We'll save the image to a file for later comparison.

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

Let's import the Ruby logo and see what it looks like:

```ruby
IMAGE_WIDTH_PX = 100
IMAGE_HEIGHT_PX = 100

target_image = import_target_image("ruby_logo.png", "ruby_logo_grayscale.png")
```

<div style="text-align:center;padding:20px;border:1px solid gray;">
  <img style="border: 1px solid gray" src="/assets/images/low_poly_image_generation/ruby_logo_grayscale.png" />
  <figcaption>100x100 pixel grayscale version of the Ruby logo: our target image.</figcaption>
</div>


Using the `Magick::Image` class to represent our target image is arbitrary, but the `rmagick` library provides a convenient interface for reading, writing, and importantly, comparing images pixel-by-pixel. (We'll use this later to calculate the fitness of each member). 

## Member Genes

When defining of our objective, we identified that the genes of each member can be represented as an Array of 100 points, each with an `(x,y)` coordinate and a grayscale value that defines the vertices of triangles. We can encode this using a `Point` Struct with `x`, `y`, and `grayscale` attributes.

```ruby
Point = Struct.new(:x, :y, :grayscale)
```

> 📐 **Why a Struct?**\
> A `Struct` is a simple way to define a class with attributes. It's a good choice here because we do not need to define any behavior on `Point`-s; it is a data-only object. Based on my benchmarks[^struct_benchmarks], a hash would be more performant, through it's less flexible and less explicit. A class or Ruby 3.2 [`Data`](https://docs.ruby-lang.org/en/3.2/Data.html) object offer no additional benefits.

<!-- TODO: Add benchmarks -->
[^struct_benchmarks]: [Hash v. Struct v. Data v. Class Benchmark](https://gist.github.com/Thomascountz/f9c8912c3b6aae0345f4b4d2901ec16c)

> 🌈 **Why does a Point have color?**\
> Notice here that a the `grayscale` attribute is defined on the `Point` Struct and not on some representation of a triangle. We'll need a grayscale value to fill each triangle, but a triangle will be made up of three `Point`-s. So, which of the three `Point`-s' `grayscale` attribute do we use? We will average them. This is because, as we will see, we aren't sure which three `Point`-s will be used together as the vertices of any particular triangle. Therefore, for any given triangle, we'll average the `grayscale` values of its three `Point`-s together to determine the fill color. This is only one approach to this problem.

Now that we have a `Point`, we can create an Array of them to form a member's genes. 

The Petri Dish framework provides a `PetriDish::Member` class, which acts as an interface to the library. The `PetriDish::Member` class holds onto the `genes` Array, which is then directly exposed via the `PetriDish::Member#genes` method.

Here is the entire definition of the `PetriDish::Member` class:

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
  end
end
```

The initializer also accepts a `fitness_function` which is used to evaluate the fitness of a member. (We'll define the fitness function later, but for now, it only needs to respond to `#call` and take a `PetriDish::Member` as its only argument).

To create a `PetriDish::Member` with an Array of 100 random `Point`-s as its genes, we do the following:

```ruby
GRAYSCALE_RANGE = 0..255

def random_member
  genes = Array.new(100) do
  Point.new(rand(0..IMAGE_WIDTH_PX), rand(0..IMAGE_HEIGHT_PX), rand(GRAYSCALE_RANGE)) 
  end

  PetriDish::Member.new(genes: genes, fitness_function: ->(_member) { })
end

puts random_member.genes.sample(3)
#<struct Point x=57, y=21, grayscale=235>
#<struct Point x=16, y=49, grayscale=64>
#<struct Point x=68, y=6, grayscale=210>
```

## _Reconstructed_ Output Image

To turn a `PetriDish::Member` into a low-poly image, we'll create triangles using its `#genes` in a process called [_Delaunay triangulation_](https://en.wikipedia.org/wiki/Delaunay_triangulation). This technique takes a set of points and creates a set of triangles such that no point is inside the circumcircle of any triangle, i.e. no triangle overlaps another. The [`delaunator`](https://github.com/hendrixfan/delaunator-ruby/tree/master) gem is a Ruby library that performs Delaunay triangulation, and we'll use it here instead of implementing it ourselves.

Let's define a function called `member_to_image` that takes a `PetriDish::Member` and returns an `Magick::Image` object based on the member's genes (while also grossly violating the single-responsibility principle).

1. We begin by initializing a new `Magick::Image` object, which is the same object type as our input image. 
2. We then perform the Delaunay triangulation using the `Delaunator.triangulate` method and passing in the `x` and `y` values from the `Point`-s returned from the `PetriDish::Member#genes` method. 
3. To determine the grayscale fill value, we use the `grayscale` value from `PetriDish::Member#genes`, and average them, as we discussed earlier.
4. Finally, we draw each triangle onto the image using the `Magick::Draw#polygon` method.

```ruby
require 'petri_dish'
require 'delaunator'

def member_to_image(member)
  # Create a new image with a white background
  image = Magick::Image.new(IMAGE_WIDTH_PX, IMAGE_HEIGHT_PX) { |options| options.background_color = "white" }

  # Create a new draw object to draw onto the image
  draw = Magick::Draw.new

  # Perform Delaunay triangulation on the points
  #
  # Delaunator.triangulate accepts a nested array of [[x1, y1], [xN, yN]]
  # coordinates and returns an array of triangle vertex indices where each
  # group of three numbers forms a triangle
  triangles = Delaunator.triangulate(member.genes.map { |point| [point.x, point.y] })

  triangles.each_slice(3) do |i, j, k|
    # Get the vertices of the triangle
    triangle_points = member.genes.values_at(i, j, k)

    # Use the average color from all three points as the fill color
    color = triangle_points.map(&:grayscale).sum / 3

    # The `Magick::Draw#fill` method accepts a string representing a color in the form "rgb(r, g, b)"
    draw.fill("rgb(#{color}, #{color}, #{color})")

    # Magick::Image#draw takes an array of vertices in the form [x1, y1,..., xN, yN]
    vertices = triangle_points.map { |point| [point.x, point.y] }
    draw.polygon(*vertices.flatten)
  end

  draw.draw(image)
  image
end
```

Let's see what the result looks like if we run it a few times:

```ruby
5.times do |i|
  member_to_image(random_member).write("member#{i}.png")
end
```

<div style="text-align:center; margin: 10px auto 10px auto;">
  <img style="border:1px solid black" src="/assets/images/low_poly_image_generation/random_members.png" />
  <figcaption>Five random members of the population.</figcaption>
</div>

Here, we can see the Delaunay triangulation in action. Each member has a different set of points, and therefore a different set of triangles. We can also see that the grayscale values are being averaged together to determine the fill color of each triangle.

When we use an `Magick::Image` object to represent a member of the population, we do so to easily compare it to the `Magick::Image` target object and visualize the results from the algorithm.

When we use the `Petridish::Member` object to represent the same member, we do so to enable the algorithm to easily calculate and evolve new members.

This type of data engineering, akin to _feature engineering_ in machine learning, is a critical step in the process of developing an evolutionary algorithm. The way we encode the problem and represent potential solutions has a large impact on the performance of the algorithm and our ability to interpret its output.

> ⬜️ **Why the White Background?**\
> When we create a new `Magick::Image` object to represent a member in the `member_to_image` method, we opt for `white` as the background color. This choice, although arbitrary, influences the performance of the algorithm. For instance, with the grayscale Ruby logo, whose background is largely white, starting with a white background might expedite the convergence on a solution. However, hardcoding this value may bias the algorithm towards reconstructing targets with white backgrounds. The best solution would be to make this choice configurable in order to make this parameter tunable. This is a good example of how the smallest details in the way we model a problem can impact the performance of the algorithm.

# Fitness Function

The fitness function is a function that takes a `Member` and returns a number that represents how well that member solves the problem. In our case, we want to know how well a member approximates the target image.

Modeling a fitness function to map to the search space is often the most difficult part of developing an evolutionary algorithm. It's also the most important part because it's what the algorithm uses to determine which members are better than others. Two key qualities of a fitness function are *determinism* and *discrimination*.

Deterministic means that given the same `Member`, the fitness function should always return the same fitness score. This is because the fitness of a member may be evaluated multiple times during the evolutionary process, and inconsistent results could lead to unpredictable behavior.

Discriminative means that the fitness function should be able to discriminate between different members of the population. That is, members with different genes should have different fitness scores. Although fitness function do not have to be strictly discriminative, if many members have the same fitness score, the evolutionary algorithm may have a harder time deciding which members are better.

Lucky for us, the `rmagick` library provides an [`Image#difference`](https://rmagick.github.io/image1.html#distortion_channel) method that fits the bill. `Image#difference` compares two images and returns three numbers that represent how different they are: `mean_erorr_per_pixel`, `normalized_mean_error`, and `normalized_maximum_error`. We'll use the `mean_error_per_pixel` to calculate our fitness score.

```ruby
require 'petri_dish'
require 'rmagick'

  def calculate_fitness(target_image)
    ->(member) do
      member_image = member_to_image(member, IMAGE_WIDTH_PX, IMAGE_HEIGHT_PX)
      # Magick::Image#difference returns a tuple of:
      # [mean error per pixel, normalized mean error, normalized maximum error]
      (1.0 / target_image.difference(member_image)[1])**2 # Use normalized mean error
    end
  end
```

The fitness function is a lambda that takes a `Member` and returns a fitness score. The number is the inverse of the mean error per pixel between the target image and the image generated from the member, squared. This means that the higher the fitness score, the better the member approximates the target image.

> 2️⃣ **Why squared?**\
> Squaring the mean error per pixel means that the fitness score will increase exponentially as the member gets closer to the target image. This is a good thing because it means that as we get closer to the target, the algorithm will be more sensitive to small changes in the member's genes. Other fitness functions may be directly linear, and others still may require more complex transformations.

> 🙃 **Why the inverse?**\
> The mean error per pixel measures the _error_ of a solution, which we want to _minimize_. However, since evolutionary algorithms are designed to _maximize_ fitness, we take the inverse of the error. As a result, solutions with smaller errors (which are better) will have larger fitness values, and the algorithm will correctly try to maximize fitness, and therefore minimize error.[^inverted-error]

[^inverted-error]: If we don't invert the error, the algorithm will try to maximize the error. In the case of image reconstruction, this will result in an inverted image. This isn't what we're going for here, but it demonstrates the creativity of evolutionary algorithms.

Lastly, we define `#calculate_fitness` as a lambda because the Petri Dish framework requires the `fitness_function` to respond to `#call`. The framework will call this lambda via the `#fitness` method on `Member` in order to memoize and return the fitness score. We use a closure here so that the `target_image` is available to the lambda when it's called.

> 📫 **Closures**\
> _Closures_ are a powerful feature of Ruby and other languages. They allow us to define a function that can be called later, but that also has access to the variables that were in scope when the function was defined. It's like putting a note inside an envelope for the function to open later. In our case, we want to define a function that can be called later by the Petri Dish framework, but that also has access to the `target_image` that we defined earlier.


Now that we have a way to represent a member of the population and a way to evaluate the fitness of a member, we can start to evolve the population by defining the evolutionary operators.

# Genetic Operators

The genetic operators are the functions that we use to evolve the population generation after generation—they are what allow the algorithm to navigate the vast search space of potential solutions.

The operators we'll take a look at are grouped by _selection_, _crossover_, _mutation_, and _replacement_.

## Parent Selection Function

Selection is the process of choosing which members of the population are the most fit and therefore should be used as _parents_ to create the next generation of _children_. There are many different selection strategies, but for our task, we'll use one called _fitness proportionate selection_.

Also called _roulette wheel selection_ or _stochastic acceptance_, fitness proportionate selection works by assigning each member a weighted probability of being selected as a parent, and then randomly selects parents based on those probabilities.

The weighted probability assigned to each member is proportional to that member's fitness score, which means that members with higher fitness scores are more likely to be selected.

For example, let's say we have the following `Member`-s with the following fitness scores:

```ruby
population = [
  Member.new(genes: [1, 2, 3], fitness_function: ->(_member) { 2 }),
  Member.new(genes: [4, 5, 6], fitness_function: ->(_member) { 3 }),
  Member.new(genes: [7, 8, 9], fitness_function: ->(_member) { 5 }),
]
```

To calculate the proportional fitness for each member, we divide the member's fitness by the total fitness of the population. In our case, the total fitness is `2 + 3 + 5 = 10`. Dividing each members' fitness by this number gives us the proportion of the total fitness that that member contributes. 

If we calculate a proportional fitness for each member from our example, we get the following results:

```ruby
weights = population.map { |member| member.fitness / population.sum(&:fitness).to_f }
# => [0.2, 0.3, 0.5]
```

In our example, if we were to select multiple members using these weighted probabilities, we would expect to get the first member (`population[0]`) 20% of the time, the second member (`population[1]`) 30% of the time, and the third member (`population[2]`) 50% of the time.

We can then use these proportional fitnesses, to _weigh_, or _bias_ the otherwise equally random probability of each member being selected.

Here's what that looks like:

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

The proportional fitness is calculated by dividing the member's fitness by the total population fitness, like before. Then, we raise a random number between 0 and 1 to the inverse of the proportional fitness in order to bias the selection towards members with higher fitness scores. The `Enumberable#max_by(2)` method is used to select two members with the highest result from the block.

The maths are a bit annoying to me personally, but nevertheless, the result of all of this is like spinning a roulette wheel where the size of each slice is proportional to the member's fitness. The higher the fitness, the larger the slice, and the more likely the member is to be selected.

Notice how the parent selection function makes no mention of `Point`-s or `Magick::Image`-s. This is because the selection function is generic and can be used for any problem. It only needs to know how to select members based on their fitness scores.

There are many other selection methods, like simply selecting the fittest members (elite selection) or by first choosing a random subset of the population and then choosing the fittest amongst those (tournament selection). 

The benefit of fitness proportional selection is that it allows for a balance between _exploration_ (trying new things) and _exploitation_ (using what we know works). This is because members with lower fitness scores still have a chance of being selected, but members with higher fitness scores are more likely to be selected. 

This is the selection method we'll use for our task, but it may be worth experimenting with other selection methods to see if they work better for our problem.

> 👨‍👨‍👦 **Multiple Parents**\
> Although most implementations of evolutionary algorithms that I've seen select two parents, it is possible to select more than two. In fact, the Petri Dish framework allows for any number of parents to be inside the Array returned by the selection function lambda.


## Crossover Function

In biology, crossover is when paired chromosomes from each parent swap segments of their DNA. This creates new combinations of genes, leading to genetic diversity in offspring. In evolutionary algorithms, crossover is the process of combining the genes of parents members to create a new child member.

After selecting parents, their genes, an Array of `Point`-s in our case, are combined to create a new `Petridish::Member`. There are many different ways to combine the genes of parents, but for our task, we'll use a method called _random midpoint crossover_ to crossover two parents.

Random midpoint crossover works by randomly selecting a midpoint in the genes of each parent and then combining the genes before and after that midpoint to create a new child. Specifically, we'll randomly select a midpoint between `0` and the length of the genes Array, and then take the genes before that midpoint from the first parent and the genes after that midpoint from the second parent.

For example, say we have two parents with the following genes:

```ruby
parent_1 = PetriDish::Member.new(
  genes: [
    Point.new(1, 2, 25),
    Point.new(3, 4, 50),
    Point.new(5, 6, 100),
  ],
  # fitness_function: ...
)
parent_2 = PetriDish::Member.new(
  genes: [
    Point.new(7, 9, 125),
    Point.new(9, 10, 150),
    Point.new(11, 12, 200),
  ],
  # fitness_function: ...
)
```

If we were to perform random midpoint crossover on these parents, and the `midpoint = 1`, we would get the following child:

```ruby
child = PetriDish::Member.new(
  genes: [
    Point.new(1, 2, 25),
    Point.new(9, 10, 50),
    Point.new(11, 12, 200),
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

Note again, our function returns a lambda, as required by the Petri Dish framework. The lambda takes an Array of parents and returns a new `PetriDish::Member` with the combined genes of the parents, while also passing along the `fitness_function` from the configuration object captured by the closure. As before, the fitness function works generically and does not need to know about `Point`-s or `Magick::Image`-s.

Other crossover methods include _uniform crossover_, where each gene is randomly selected from either parent, and _majority rule crossover_, which works well for instances of selecting more than two parents. It works by having each gene of the offspring determined by a majority vote among the parents. If the parents have equal votes, one parent is chosen randomly to determine the gene.

Random midpoint crossover is a good choice for starting out for its simplicity, but again, it's worth experimenting with other crossover methods to see if they work better for a particular problem. (In fact, its possible to use one genetic algorithm to optimize the genetic operators of another genetic algorithm, but that's a topic for another day...).

> 👩‍🔬 **Meta Experimentation**\
> This type of meta experimentation is akin to hyperparameter tuning in machine learning. A core design philosophy of the Petri Dish framework is to make it easy to experiment with different configurations in this way. By passing in different functions for the genetic operators, we can easily experiment with different configurations and observe which ones work best.

That said, for our task, random midpoint crossover works well enough, so we'll stick with it for now.

## Mutation Function

Mutation is the process of randomly changing the genes of a child member after crossover. Combining well-fit parents can get us a long way towards a great solution, but mutation is done to introduce new genetic material into the population. 

There are many different ways to mutate a member, but for our task, we'll use a domain-specific implementation that I call _nudge mutation_.

> 🧬 **Why mutate at all?**\
> Mutation is not strictly necessary for an evolutionary algorithm to work. However, mutation increases diversity and diversity is what allows the algorithm to explore the search space more thoroughly. Without mutation, the algorithm may get stuck in a local maximum, i.e. be unable to find a better solution, though one may exist. Mutation allows the algorithm to escape this local maximum and continue searching for a better solution.

If we think back to our genes as an Array of `Point`-s, then nudge mutation is the process of randomly moving each point's position and grayscale value by a small amount. 

This is done by adding a random number between `-10` and `10` to the `x` and `y` coordinates of each point `clamp`-ed between the image dimensions. And, adding a random number between `-25` and `+25` to the grayscale value `clamp`-ed between `0..255` (i.e. valid grayscale values).

If we implemented this as a lambda for the Petri Dish `mutation_function` configuration (RBS type `Proc[Member, Member]`), it might look something like this:

```ruby
  def nudge_mutation_function(configuration)
    ->(member) do
      mutated_genes = member.genes.dup.map do |gene|
        Point.new(
          (gene.x + rand(-10..10)).clamp(0, IMAGE_WIDTH_PX),
          (gene.y + rand(-10..10)).clamp(0, IMAGE_HEIGHT_PX),
          (gene.grayscale + rand(-25..25)).clamp(GRAYSCALE.min, GRAYSCALE_RANGE.max)
        )
        end
      PetriDish::Member.new(genes: mutated_genes, fitness_function: configuration.fitness_function)
    end
  end
```
However, we don't want to mutate every gene of a child; we want to preserve qualities from the parents and strike a balance between exploration and exploitation. Therefore, we use a _mutation rate_ to determine the probability that any particular gene will be mutated.

For example, if the mutation rate is `0.1`, then there is a 10% chance that a gene will be mutated.

If we add the concept of a mutation rate to our mutation function, we get this:

```diff
def nudge_mutation_function(configuration)
  ->(member) do
    mutated_genes = member.genes.dup.map do |gene|
+      if rand < configuration.mutation_rate
        Point.new(
          (gene.x + rand(-10..10)).clamp(0, IMAGE_WIDTH_PX),
          (gene.y + rand(-10..10)).clamp(0, IMAGE_HEIGHT_PX),
          (gene.grayscale + rand(-25..25)).clamp(GRAYSCALE.min, GRAYSCALE_RANGE.max)
        )
+      else
+        gene
+      end
    end
    PetriDish::Member.new(genes: mutated_genes, fitness_function: configuration.fitness_function)
  end
end
```

Here, we use the `configuration.mutation_rate` to determine whether or not to mutate each gene. If the random number is less than the mutation rate, we mutate the gene, otherwise, copy it over to the new `PetriDish::Member` as-is.

> 📈 **Determining the mutation rate**\
> The mutation rate is a hyperparameter that can be tuned to improve the performance of the algorithm. A higher mutation rate will increase diversity, but it may also cause the algorithm to take longer to converge. A lower mutation rate will decrease diversity, but it may also cause the algorithm to get stuck in a local maximum. The mutation rate is often a good hyperparameter to tune when trying to improve the performance of an evolutionary algorithm.[^high-mutation-rate] 

[^high-mutation-rate]: `0.1` is somewhat of a high mutation rate, but as we'll see later, this value was chosen because it worked well for my particular configuration of the problem.

Other common types of mutation strategies include _swap mutation_, where two genes' positions are randomly swapped, and _scramble mutation_, where a random subset of genes are randomly shuffled. Like all other genetic operators, the best strategy for the problem at hand is highly dependent on the problem itself and is often worth experimenting with.

In our case, the mutation function implementation was developed to represent the idea of nudging around the points of a polygon until the resulting image looks like the target image.

> 🪲 **Point jitter??**\
> You may see that in the [actual implementation](https://github.com/Thomascountz/petri_dish/blob/133be9efea42e7e3f62e01cd92a77ba03425afa4/examples/low_poly_reconstruction/low_poly_reconstruction.rb#L115-L130) of this method, I've added a `point_jitter` of `rand(-0.0001..0.0001)` to each `x` and `y` of `Point`. This is because the particular implementation of the Delaunay algorithm would fall into a divide-by-zero error if all of the points were collinear (on exactly on the same line). This is a good example of how reality is often messier than theory, and how we must adapt our models and implementation to the problem at hand.

Now that we have a way to select parents, combine their genes, and mutate the resulting child, we can start to evolve the population. The last step is to define how we'll replace the old population with the new population.

## Replacement

In the most simple case, we can replace the entire population with the new population, sometimes called _generational replacement_. This often works well, but it can sometimes cause _too much_ diversity, which can cause the algorithm to take longer to converge as some of the most-fit members are lost. To prevent this, we can use a technique called _elitism_.

Elitism, which I personally like to call _grandparenting_, is the process of preserving the fittest members of the population from one generation to the next. This is done by taking the top `n` members of the population and adding them to the new population. The rest of the new population is filled with the children of the parents.

In the Petri Dish framework, we tune this parameter using the `elitism_rate` configuration value. This is the proportion of the population that is preserved through elitism. For example, if the elitism rate is `0.1`, then the top 10% of the population will be preserved through to the next generation.

Other replacement strategies include _steady-state replacement_, where only a single member of the population is replaced with a child, and _age-based replacement_, where the oldest members of the population are replaced with children.

For our image reconstruction task, we'll use generational replacement with grandparenting set to `0.05`, or 5%.

## End Condition

Lastly, we need to define when the algorithm should stop. The two most common end conditions are 1) when a member of the population meets the criteria, or 2) when a certain number of generations have passed. We'll use the latter.

An `end_condition_function` can otherwise be used to determine if any of the members of the population meets a particular criteria. For example, if we were trying to find a member of the population that had a fitness score of `1.0`, we could use an `end_condition_function`. Alternatively, we could run the algorithm for a given amount of wall time, or until the rate of improvement drops below a certain threshold.

In our case, we'll use the `max_generations` configuration value to determine when the algorithm should stop. This is the maximum number of generations that the algorithm will run for, regardless of the fitness of the members of the population. I have found that `5000` generations is enough to get a good approximation of the target image, but not so many that it takes too long to run.

We now have all of the pieces we need to put together our evolutionary algorithm. Let's see how it all works!

# Putting it Together

Before we look at the results, let's recap everything we've gone over.

1. A genetic algorithm is a type of evolutionary algorithm that uses genetic operators to evolve a population of members towards a solution to a problem.
2. We start the algorithm design by identifying our objective, defining our decision variables and search space, and defining our constraints.
3. We then define a way to represent a member of the population and a way to evaluate the fitness of a member.
   1. In our case, we represent a member of the population as an `Magick::Image` object, and we evaluate the fitness of a member by comparing it to the target image using the `Magick::Image#difference` method.
   2. We also represent a member of the population as a `PetriDish::Member` object with an Array of `Point`-s as genes, which is used by the Petri Dish framework to evolve the population.
4. The genetic operators are selection, crossover, mutation, and replacement.
   1. Selection is the process of choosing which members of the population are the most fit and therefore should be used as _parents_ to create the next generation of _children_.
   2. Crossover is the process of combining the genes of parents members to create a new child member.
   3. Mutation is the process of randomly changing the genes of a child member after crossover.
   4. Replacement is the process of replacing the old population with the new population.
5. The end condition is the criteria that determines when the algorithm should stop.
   1. In our case, we'll use the `max_generations` configuration value to determine when the algorithm should stop. This is the maximum number of generations that the algorithm will run for, regardless of the fitness of the members of the population.

## Final Configuration

The following is the configuration from the [actual implementation](https://github.com/Thomascountz/petri_dish/blob/133be9efea42e7e3f62e01cd92a77ba03425afa4/examples/low_poly_reconstruction/low_poly_reconstruction.rb#L42-L56) and contains all of the pieces we've discussed so far, with the addition of a few callbacks that the framework provides.

```ruby
def configuration
  PetriDish::Configuration.configure do |config|
    config.population_size = 50
    config.mutation_rate = 0.05
    config.elitism_rate = 0.05
    config.max_generations = 10_000
    config.fitness_function = calculate_fitness(target_image)
    config.parents_selection_function = roulette_wheel_parent_selection_function
    config.crossover_function = random_midpoint_crossover_function(config)
    config.mutation_function = nudge_mutation_function(config)
    # TODO: Don't pass in image dimensions, use constants instead
    config.highest_fitness_callback = ->(member) { save_image(member_to_image(member, IMAGE_WIDTH_PX, IMAGE_HEIGHT_PX)) }
    config.generation_start_callback = ->(current_generation) { generation_start_callback(current_generation) }
    config.end_condition_function = nil
  end
end
```

The `highest_fitness_callback` is invoked when a member with the highest fitness seen so far is found. When that happens, we save the image to a file so that we can see the progress of the algorithm.

The `generation_start_callback` is invoked at the start of each generation. We use this to keep track of the progress of the algorithm to do things like name the output images.

The last piece of the configuration we haven't discussed yet is the `population_size`. This is the number of members in the population per generation, and like all other pieces of configuration, is a hyperparameter that should be tuned to improve the performance of the algorithm. A larger population size can increase diversity, but it may also cause the algorithm to take longer to converge. A smaller population size can decrease diversity, but can be aided with a higher mutation rate and maximum number of generations, as we've done here.

# Results

Finally, it's time to run the algorithm and see what happens! Let's take a subjective look at the results before we get into the numbers.

## Subjective Results

After running the algorithm for over 6000 generations, after about an hour, I'm really please with the results!

{% include low_poly_image_generation/generation_slider.html %}

<div style="text-align:center">
  <img style="border: 1px solid gray; padding: 20px" src="/assets/images/low_poly_image_generation/skip_montage.png" />
  <figcaption>Output of the <code>highest_fitness_callback</code> calls show a progressively more refined low-poly representation</figcaption>
</div>

## Notes
- Use the inverse normalized error instead
- Non-random initialization