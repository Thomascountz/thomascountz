---
title: Safer Monkey Patching in Ruby
author: Thomas Countz
tags: ["ruby"]
layout: post
---

At 8th Light, my team and I are rigorously working on our most important client’s most important project: a command line Battleship gem, called [battle_boats](https://rubygems.org/gems/battle_boats). \s

I recently sat down with my mentors and demo-ed version `0.0.4`, where I added a bit of color in dev mode, and my mentors-as-stakeholders liked it so much, they’ve asked for more color! But how??

“It should be easy,” I thought. I already had some implementation ideas in mind thanks to this [SO answer](https://stackoverflow.com/a/11482430) detailing how to open up the `String` class to add color methods that use`ANSI` codes.

It goes something like this:

```ruby
class String
  def blue
    "\e[34m#{self}\e[0m"
  end

  def red
    "\e[31m#{self}\e[0m"
  end

  def yellow
    "\e[33m#{self}\e[0m"
  end
end
```

So, we open up the `String` class and use the `ANSI` color codes to output our strings in color in `ANSI`-supported terminals.

This allows us to do this:

```ruby
puts "Hello, World!".blue
#=> Hello, World! (in blue)
```

# So What’s The Problem?

Being that this product is a Ruby gem, everything is namespaced under the module `BattleBoats`, so when I tried implementing this, it looked like this:

```ruby
module BattleBoats
  class String
    # implementation
  end
end
```

I was surprised that this didn’t work, but I soon realized that in this instance, we’re not opening `String`, we’re defining `BattleBoats::String`. Not the same thing, and not what we want.

The fix is easy, right? Just don’t wrap it in the `BattleBoats` module. But that left me feeling antsy. There was something about polluting the `String` class in a global scope that didn’t sit right with me; it felt like an irresponsible use of metaprogramming.

# Defining Pure Functions

I could always just define a new module and pass strings into its methods:

```ruby
module BattleBoats
  module Colorize
    def blue(string)
      "\e[34m#{string}\e[0m"
    end
  end
end
```

This implementation just requires that we pass our string into our method to get the encoding we need to output in color:

```ruby
include BattleBoats::Colorize
puts blue("Hello, World!")
#=> Hello, World! (in blue)
```

But this just seemed less fun. I have a chance to use monkey patching here, and you should always take advantage of every opportunity to use monkey patching!! /s

# Using instance_eval

Another option I could think of was to define the color methods only on the instances of `String` that I need them. For example,

```ruby
module BattleBoats
  def colorify(string)
    string.instance_eval do
      def blue(string)
        "\e[34m#{self}\e[0m"
      end
    end
  end
end
```

This implementation gives us the best of both worlds. 1) We get to call methods directly on the strings we want to colorize, and 2) we don’t effect any other `String` instances. It does have the downside of requiring an extra step, but no more than our previous approach:

```ruby
include BattleBoats
puts colorify("Hello, World").blue
#=> Hello, World! (in blue)
```

This has the added advantage of allowing us to easily add new colors to the `colorify`'d strings.

---

None of these implementations are bad, but I really really wished for a way to open up the `String` class _only_ when I included the module where the actual methods were defined…

```ruby
puts "Hello, World".blue
#=> NoMethodError: undefined method 'blue' for "Hello, World!":String

include Colorize
puts "Hello, World!".blue
#=> Hello, World! (in blue)
```

It turns out there is a metaprogramming technique to do exactly that!

# Introducing Refinements

> Due to Ruby’s open classes you can redefine or add functionality to existing classes. This is called a “monkey patch”. Unfortunately the scope of such changes is global. All users of the monkey-patched class see the same changes. This can cause unintended side-effects or breakage of programs.

> Refinements are designed to reduce the impact of monkey patching on other users of the monkey-patched class. Refinements provide a way to extend a class locally.

> —[ Ruby Core Docs](https://ruby-doc.org/core-2.1.1/doc/syntax/refinements_rdoc.html)

---

It’s exactly what I was looking for! Scoped monkey patching!

```ruby
module BattleBoats
  module Colorize
    refine String do
      def blue(string)
        "\e[34m#{string}\e[0m"
      end
    end
  end
end
```

We use it like this:

```ruby
puts "Hello, World".blue
#=> NoMethodError: undefined method 'blue' for "Hello, World!":String

using Colorize
puts "Hello, World!".blue
#=> Hello, World! (in blue)
```

Where the keyword for introducing the refinement module is `using` rather than `include`.

Now I can keep my `Colorize` methods away from the `String`'s in the rest of the system and keep my conscious clear that I won’t introduce unexpected behavior in our very important client’s software!

---

Jokes aside, my exposure to metaprogramming and monkey patching has been fraught with warnings, so I’ve never really investigated the power it gives developers to write expressive code. Of course there are other ways of solving this problem, but given the opportunity to make safe use of this technique was just too exciting to pass up.

