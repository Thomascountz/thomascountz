---
title: "Ruby Closures: Messing with Memory"
subtitle: Lexical scope, binding environments, and object lifetimes
author: Thomas Countz
layout: post
featured: true
tags: ["ruby"]
---

At its core, a closure is a function that carries a backpack.

That backpack contains all the variables that were in scope when the function was defined. Even if you execute that function in a completely different context later, it can still reach into its backpack and find the variables it captured originally.

In Ruby, we use closures constantly—via blocks, `Procs`, and lambdas. But if we slow down and look at the internals, we can see exactly *how* Ruby pulls this off.

## The "Magic" Trick

Let’s look at a classic counter.

```ruby
def create_counter
  count = 0
  -> { count += 1 }
end

my_counter = create_counter
```

If we were thinking strictly in terms of standard stack frames, `create_counter` runs, sets `count` to `0`, and returns. Once that method returns, its local variables *should* be popped off the stack and disappear.

But they don’t.

```ruby
puts my_counter.call # => 1
puts my_counter.call # => 2
```

The lambda held onto `count`. To see how, we need to look at how Ruby parses (Prism) and compiles (YARV) this code.

## 1. The AST: Measuring the Depth

Before Ruby runs code, it uses the **Prism** parser to turn your code into an Abstract Syntax Tree (AST). This is the step where Ruby realizes that the variable inside the lambda actually belongs to the scope outside of it.

If we inspect the AST for our counter code, Prism gives us a map of exactly where everything lives:

```ruby
# ... inside the LambdaNode ...
@ LocalVariableOperatorWriteNode (location: (3,7)-(3,17))
├── flags: newline
├── name_loc: (3,7)-(3,12) = "count"
├── binary_operator_loc: (3,13)-(3,15) = "+="
├── value:
│   @ IntegerNode (location: (3,16)-(3,17))
│   ├── flags: static_literal, decimal
│   └── value: 1
├── name: :count
├── binary_operator: :+
└── depth: 1  <----------------- RIGHT HERE
```

That `depth: 1` shows that the parser has identified `count` as a variable that lives *one level up* from the lambda itself.

*   `depth: 0`: Variables local to the lambda itself
*   `depth: 1`: Variables in the surrounding scope (the method)


## 2. The Bytecode: Reaching Up the Stack

When Ruby compiles this AST into bytecode for the VM (YARV), that `depth: 1` is translated directly into an instruction.

We can view the compiled bytecode using `RubyVM::InstructionSequence`. The output tells us exactly how the VM handles memory.

First, look at the parent stake frame where, `create_counter` is defined. It's local table contains `count` at index `0`, set using the `setlocal_WC_0` instruction:

```text
== disasm: #<ISeq:create_counter@<compiled>:1 (1,0)-(4,3)>
local table (size: 1, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] count@0

 putobject_INT2FIX_0_                                             (   2)[LiCa]
 setlocal_WC_0                          count@0
 putspecialobject                       1                         (   3)[Li]
 send                                   <calldata!mid:lambda, argc:0, FCALL>, block in create_counter
 leave                                                            (   4)[Re]
```

Now, look at the stack frame for the the lambda. When it wants to increment `count`, it uses a different instruction:

```text
== disasm: #<ISeq:block in create_counter@<compiled>:3 (3,4)-(3,19)>

 getlocal_WC_1                          count@0                   (   3)[LiBc]
 putobject_INT2FIX_1_
 opt_plus                               <calldata!mid:+, argc:1, ARGS_SIMPLE>[CcCr]
 dup
 setlocal_WC_1                          count@0
 leave                                  [Br]
```

This is the mechanics of the closure: `getlocal_WC_1` and `setlocal_WC_1`.

`WC_0` and `WC_1` are specializations of the `getlocal` and `setlocal` instructions that tell the VM where to look for variables. Because getting a variable from the current frame and the parent frame are so common, these optimizations exist to speed things up.

Because the lambda relies on `count@0` from its parent frame's local table (`[get|set]local_WC_1`), Ruby's GC knows it must preserve that variable, even if it would normally be marked after going out of scope. It can't just throw away the `create_counter` stack frame when the method exits, because the lambda still has a live reference pointing to it.

## Why This Matters

The implication of closures retaining access to variables is that they can keep those variables alive longer than expected. This means that while local variables in a method are typically marked for garbage collection when the method exits, variables captured by a closure remain alive as long as the closure itself is accessible.

Practically speaking, it's worth being mindful of what data you capture in a closure
