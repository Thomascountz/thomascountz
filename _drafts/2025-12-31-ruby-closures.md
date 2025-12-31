---
title: "Exploring Ruby Internals Through Closures"
subtitle: Using Prism, YARV, Binding, and ObjectSpace to understand Ruby's behavior
author: Thomas Countz
layout: post
featured: true
tags: ["ruby"]
---

Ruby abstracts away a lot of complexity. Most of the time, that's exactly what we want. But when something surprises us—a variable that sticks around longer than expected, or memory that doesn't get freed—it helps to have tools for peeking under the hood.

In this post, we'll use **closures** as a case study to explore four tools for understanding Ruby's behavior:

1. **Prism** — Ruby's parser, which builds an Abstract Syntax Tree (AST)
2. **YARV** — Ruby's bytecode VM, which executes compiled instructions
3. **Binding** — Ruby's way of reifying a closure's captured environment
4. **ObjectSpace** — A way to inspect what objects exist in memory

All examples use Ruby 4.0.0.

## The Setup: With and Without a Closure

Let's start with two similar methods. One returns a string directly; the other returns a lambda that produces the string:

```ruby
# Without closure
def greet_once(name)
  "Hello, #{name}!"
end

# With closure
def greet_later(name)
  -> { "Hello, #{name}!" }
end
```

Both produce the same output eventually:

```ruby
greet_once("World")       # => "Hello, World!"
greet_later("World").call # => "Hello, World!"
```

But internally, they're quite different. Let's see how.

## 1. Comparing the AST with Prism

Ruby's Prism parser turns source code into an Abstract Syntax Tree before execution. We can inspect this tree to see how Ruby understands our code at parse time.

```ruby
require 'prism'

code = <<~RUBY
  def greet_once(name)
    "Hello, \#{name}!"
  end
RUBY

puts Prism.parse(code).value.inspect
```

In the non-closure version, when Ruby encounters `#{name}`, it produces a `LocalVariableReadNode` with `depth: 0`:

```text
└── @ LocalVariableReadNode (location: (2,12)-(2,16))
    ├── flags: ∅
    ├── name: :name
    └── depth: 0
```

Now let's look at the closure version:

```ruby
code = <<~RUBY
  def greet_later(name)
    -> { "Hello, \#{name}!" }
  end
RUBY

puts Prism.parse(code).value.inspect
```

Inside the lambda, the same variable reference shows `depth: 1`:

```text
└── @ LocalVariableReadNode (location: (2,17)-(2,21))
    ├── flags: ∅
    ├── name: :name
    └── depth: 1
```

The `depth` field tells us how many scopes up Ruby needs to look to find the variable:

- `depth: 0` — The variable is local to the current scope
- `depth: 1` — The variable is one scope up (the enclosing method)

This is **lexical scope analysis** happening at parse time. Ruby has already figured out that the lambda needs to capture `name` from its parent scope.

## 2. Comparing the Bytecode with YARV

When Ruby compiles the AST into bytecode for the YARV virtual machine, that `depth` information translates into specific instructions. We can inspect this using `RubyVM::InstructionSequence`:

```ruby
code = <<~RUBY
  def greet_once(name)
    "Hello, \#{name}!"
  end
RUBY

puts RubyVM::InstructionSequence.compile(code).disasm
```

The non-closure version uses `getlocal_WC_0` to read `name`:

```text
== disasm: #<ISeq:greet_once@<compiled>:1 (1,0)-(3,3)>
local table (size: 1, argc: 1 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] name@0<Arg>
0000 putobject                              "Hello, "                 (   2)[LiCa]
0002 getlocal_WC_0                          name@0
0004 dup
...
```

Now the closure version:

```ruby
code = <<~RUBY
  def greet_later(name)
    -> { "Hello, \#{name}!" }
  end
RUBY

puts RubyVM::InstructionSequence.compile(code).disasm
```

The lambda's bytecode uses `getlocal_WC_1` instead:

```text
== disasm: #<ISeq:block in greet_later@<compiled>:2 (2,4)-(2,26)>
0000 putobject                              "Hello, "                 (   2)[LiBc]
0002 getlocal_WC_1                          name@0
0004 dup
...
```

The `WC_0` and `WC_1` suffixes are optimized versions of the general `getlocal` instruction:

- `getlocal_WC_0` — Get a variable from the current frame (depth 0)
- `getlocal_WC_1` — Get a variable from the parent frame (depth 1)

This is the mechanism that makes closures work: the VM knows to reach up into the parent frame's local variable table.

## 3. Inspecting Captured Variables with Binding

Ruby reifies a closure's captured environment as a `Binding` object. We can use this to inspect exactly what a closure has access to:

```ruby
def create_greeter(name)
  greeting = "Hello"
  -> { binding }
end

closure_binding = create_greeter("World").call

closure_binding.local_variables
# => [:name, :greeting]

closure_binding.local_variable_get(:name)
# => "World"

closure_binding.local_variable_get(:greeting)
# => "Hello"
```

Even though `create_greeter` has returned, the closure retains access to both `name` and `greeting`. The `Binding` object lets us see exactly what's in the closure's "backpack."

## 4. Observing GC Behavior with ObjectSpace

Because closures hold references to captured variables, those variables can't be garbage collected until the closure itself becomes unreachable. We can observe this with `ObjectSpace`:

```ruby
require 'objspace'

class TrackedObject
  attr_reader :name
  def initialize(name) = @name = name
end
```

First, without a closure:

```ruby
def without_closure
  obj = TrackedObject.new("temporary")
  obj.name.upcase
end

result = without_closure
GC.start

ObjectSpace.each_object(TrackedObject).count
# => 0
```

The `TrackedObject` is gone—it became unreachable when the method returned, so GC collected it.

Now with a closure:

```ruby
def with_closure
  obj = TrackedObject.new("captured")
  -> { obj.name.upcase }
end

closure = with_closure
GC.start

ObjectSpace.each_object(TrackedObject).count
# => 1

closure.call
# => "CAPTURED"
```

The `TrackedObject` survives because the closure still references it. Only when we release the closure does the object become collectible:

```ruby
closure = nil
GC.start

ObjectSpace.each_object(TrackedObject).count
# => 0
```

## Wrapping Up

We've used closures to explore four tools for understanding Ruby internals:

| Tool | What it shows |
|------|---------------|
| **Prism** | How Ruby parses code and identifies variable scope (`depth`) |
| **YARV bytecode** | How the VM accesses variables across frames (`WC_0` vs `WC_1`) |
| **Binding** | What variables a closure has captured |
| **ObjectSpace** | What objects exist in memory and when they get collected |

These same tools work for exploring other Ruby behaviors too. Next time something surprises you, you have a few ways to peek under the hood.