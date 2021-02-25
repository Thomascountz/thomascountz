---
title: Testing Ruby’s `gets` & `puts`
subtitle: Using Dependency Injection, Sensible Defaults, & Duck-Types
author: Thomas Countz
layout: post
tags: ["ruby", "testing"]
---

### The Problem.

You want to TDD some behavior that interacts with the command line:

```
puts "Would you like to continue? [yN]"
answer = gets.chomp.downcase
```

But testing this idea is difficult; when your tests run these lines of code, they can cause your tests to hang or send unwanted output to your console.

### A Solution.

* Wrap specific puts-ing and gets-ing behavior in code that you own and control.

* Inject duck-types of the objects on which we can call puts and gets . We call puts and gets implicitly on the objects stored in the $stdout and $stdin variables , respectively. For our tests StringIO is a handy duck-type of both of these objects!

* Call puts and gets on the, now injected, objects.

* Use StringIO’s instance methods to write assertions.

### An Example Test.

```
RSpec.describe ConsoleInterface do

  describe '#ask_question' do
    it 'sends a prompt question to output' do
      output = StringIO.new
      console_interface = ConsoleInterface.new(output: output)

      console_interface.ask_question

      expect(output.string).to include("continue?")
    end
  end

  describe '#answer' do
    it 'returns a formatted string received from input' do
      input = StringIO.new("iNPut\n")
      console_interface = ConsoleInterface.new(input: input)

      expect(console_interface.answer).to eq("input")
    end
  end

end
```

### An Example Implementation.

```
class ConsoleInterface

  def initialize(input: $stdin, output: $stdout)
    @input = input
    @output = output
  end

  def ask_question
    @output.puts "Would you like to continue? [yN]"
  end

  def answer
    @input.gets.chomp.downcase
  end

end
```

### Why I Like This.

The power of Ruby is that if it [quacks like a duck, it must be a duck](https://stackoverflow.com/questions/4205130/what-is-duck-typing)! By combining this freedom with dependency injection, we can quickly grab control over our dependency on what we often take for granted: the command line.

Also, you might be excited to learn that you’ve just used a test double! They can often be seen as big scary controversial things that require you to pull in heavy libraries, but because of duck-typing, using a test-double can be as simple as injecting a built-in object that we have more control over.
