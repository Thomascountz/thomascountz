---
title: Ownership in Rust, Part 1
subtitle: It’s not my problem.
author: Thomas Countz
layout: post
tags: ["rust"]
featured: true
---

[_Ownership in Rust, Part 2_ →](/2018/07/11/ownership-in-rust-part-2)

As a Rubyist, all that I know about memory allocation is that it’s handled by some process called garbage collection and that it’s [Aaron Patterson](https://medium.com/u/64e4f5eee153)’s problem, not mine.

So, when I cracked open the [Rust Book](https://doc.rust-lang.org/book/second-edition/) and saw that one of Rust’s defining features is its alternative to garbage collection, I became a bit worried.

Was the responsibility of dealing with memory management about to be heaped onto me?

Apparently, with other system programming languages, like C, dealing with memory allocation is a big deal, and can have significant consequences when done poorly.

With all of the other new things to learn, I felt things beginning to stack up.

# Stack & Heap

No, its not a hipster clothing brand, the stack and heap are ways of managing memory at runtime.

![Stack & Heap](/assets/images/stack_and_heap.png)

First, we have the **stack**. The stack is considered fast because it stores and accesses data based on _order_. The last thing that was placed — pushed — onto\* *the stack is the first thing removed — popped — from the stack. This is referred to as *LIFO, \*Last In First Out, and means that we only need to keep track of where the top of the stack is when it comes time to free up memory.

The stack can also be fast because the amount of space needed from the stack is known at _compile_ time. This means that we can allocate a fix-size portion of memory before we store anything into it.

For example, if you know that four people are coming to your dinner party, you can decide ahead of time where everyone will sit, how much food to prepare, and practice their names before they get there. This is super efficient!

Next, we have the alternative, the **heap**. When you don’t know exactly how many people are coming to your dinner party ahead of time, you can use the heap. Using the heap means finding extra chairs and giving out name tags as more and more people arrive to your dinner party.

When data of unknown-size needs to be stored during runtime, the computer searches for memory on the heap, marks it, and returns a _pointer_, which points back to that place in memory. This is called _allocating_. You can then push this pointer onto a stack, however, when you want to retrieve the actual data, you need to follow the pointer back to the heap.

---

As I keep digging into the stack & heap rabbit hole, it seems like managing data in the heap can be difficult. For example, you need to ensure that you allow the computer to reallocate a place in memory once you’re done using it. But if one part of your code _frees_ a place in memory that another part of your code still has a pointer to, funky things can happen.

> Keeping track of what parts of code are using what data on the heap, minimizing the amount of duplicate data on the heap, and cleaning up unused data on the heap so you don’t run out of space are all problems that ownership addresses.

> - [Rust Book](https://doc.rust-lang.org/book/second-edition/)

![Ownership](/assets/images/ownership.png)

# Ownership & Scope

There are three rules about ownership in Rust:

```
Each value in Rust has a variable that’s called its *owner*.

There can only be one owner at a time.

When the owner goes out of scope, the value will be dropped.
```

The simplest illustration of this ownership magic is with variable scope:

```rust
fn main() {
  let hello = "Hello, World!";
  println("{}", hello);
} // variable `hello` is now invalid
```

Once the current function scope is over, denoted by the `}`, the variable `hello` goes out of scope, and is _dropped_.

“Well, duh!” That’s what I thought when I first read this. This is the same in most other programming languages. This is what I know as the behavior of a “locally-scoped variable.”

If this is all ownership does, I’m not sure what all the hubbub is about.

However, things get more interesting when we start passing around values and switching from using a string literal, which is stored on the stack, to using a `String` type, which is stored on the heap.

```rust
fn main() {
  let hello = "Hello, World!"; // string literal
  let hello1 = hello; // copy the value of `hello` and bind it to `hello1`
  println("{}", hello); // this works!
  
  let hello = String::from("Hello, World!"); // `String` type
  let hello1 = hello; // move the data of `hello` into `hello1`
  println("{}", hello); // error[E0382]: use of moved value: `hello`
}
```

We can see here, that when using a string literal, Rust is _copying_ the value of `hello` into `hello1`, as we might expect. But when using a `String` type, Rust _moves_ the value instead. Rust tells us that we attempted to retrieve a valued that has been moved by throwing the error:`error[E0382]: use of moved value: 'hello’`

It seems like when using a string literal, Rust will _copy_ the value of that one variable into another variable, but when we use a `String` type, it _moves_ the value instead.

In order to find out which types implement the _copy trait_ “…you can check the documentation… but as a general rule, any group of simple scalar values can be `Copy`, and nothing that requires allocation or is some form of resource is `Copy`”

#### Why Not Copy Everything?

_Updated June 13, 2018_

_For the related discussion which lead to this update, please visit this [Rust language forum thread](https://users.rust-lang.org/t/the-copy-trait-what-does-it-actually-copy/18730/24)._

![Copy trait when using &str](/assets/images/copy_trait_when_using_str.png)

The string literal, `"Hello, World!"`, is stored somewhere in read-only memory, _(neither in the stack nor heap)_, and a pointer to that string is stored on the stack. Because it’s a string literal, it usually shows up as a _reference_, meaning that we use a pointer to a string stored in permanent memory, _(see [Ownership in Rust, Part 2](https://medium.com/@thomascountz/ownership-in-rust-part-2-c3e1da89956e) for more on references)_, and it’s guaranteed to be valid for the duration of the entire program, (it has a _static lifetime)_.

Here, the pointers stored in `hello` and `hello1` are using the stack. When we use the `=` operator, Rust pushes a new copy of the pointer stored in `hello` onto the stack, and binds it to `hello1`. At the end of the scope, Rust adds a call to `[drop](https://doc.rust-lang.org/1.6.0/std/ops/trait.Drop.html)` which pops the values from the stack in order to free up memory. These pointers can be stored and easily copied to the stack because their size is known at compile-time.

![Move trait when using the heap](/assets/images/move_trait_when_using_the_heap.png)

Over on the heap, the `String` type with value `"Hello, World!"` is bound to the variable `hello` , using the `String::from` method. However, unlike the string literal, there’s more data bound to `hello` than just a pointer, and the size of this data can change during runtime. Here, the `=` operator binds the data from `hello` to a new variable `hello1`, effectively *moving *the data from one variable to another. Poor `hello` is now invalid, as per ownership rule #2: “There can only be one owner at a time.”

But why do this? Why doesn’t Rust always just make a copy of the data and bind it to the new variable?

If we think back to the differences between the stack and heap, we remember that the size of data stored on the heap is not known at compile time, which means we need to run through some memory allocation steps during runtime. This can be expensive. Depending on how much data we’re storing, we could quickly run out of memory if we sit around making copies of data all day.

Besides that, the default behavior of Rust helps protect us from memory issues that we might run into in other languages.

Part of storing data on the heap, is store a pointer to that data on the stack. However, unlike using a pointer to locate read-only memory, _like when using a string literal_, the data at the end of the pointer that leads to the heap, can change. A pointer is part of the `<<DATA>>` that is bound to the `hello` variable that stores the `String` type. If we bind the same pointer data to two different variables, it might look something like this:

![A rough sketch of copying String type data](/assets/images/rough_sketch_of_copying_string_type_data.png)

We have two variables, `hello` and `hello1`, which share ownership of the same value. This violates rule #2: “There can only be one owner at a time,” but let’s keep going.

At the end of the scope in which `hello` and `hello1` are defined, we have to _drop_ the memory in the heap, which frees it up to be used again elsewhere.

![Dropping hello1](/assets/images/dropping_hello1.png)

First, we call `drop` on the data stored at the end of the pointer bound to `hello1`, but what happens now when we call `drop` on `hello`, next?

![Double Free Error](/assets/images/double_free_error.png)

This is called a _double free error_, which I think is best summarized in this [Stack Overflow answer](https://stackoverflow.com/a/21057524):

> A double free in C, technically speaking, leads to _undefined behavior_. This means that the program can behave completely arbitrarily and all bets are off about what happens. That’s certainly a bad thing to have happen! In practice, double-freeing a block of memory will corrupt the state of the memory manager, which might cause existing blocks of memory to get corrupted or for future allocations to fail in bizarre ways (for example, the same memory getting handed out on two different successive calls of `malloc`).

> Double frees can happen in all sorts of cases. A fairly common one is when multiple different objects all have pointers to one another and start getting cleaned up by calls to `free`. When this happens, if you aren't careful, you might `free` the same pointer multiple times when cleaning up the objects. There are lots of other cases as well, though.

> —[ templatetypedef](https://stackoverflow.com/users/501557/templatetypedef)

This is what Rust is trying to prevent! By invalidating `hello`, the compiler knows to only make a call to `drop`, (which calls `free` behind the scenes), on `hello1`.

---

This is all well and good, but there are instances when we _do_ want to copy data that’s stored in the heap. Rust provides an easy way of doing that with `clone()`.

```rust
fn main() {
  let hello = String::from("Hello, World!"); // `String` type
  let hello1 = hello.clone(); // clone data from `hello` into `hello1`
  println("{}", hello); // => "Hello, World!"
}
```

Keep in mind that calls to `clone()` can be expensive, which is why Rust prevents this “deep copying” by default.

---

Apparently, there’s a lot more about Rust ownership than covered here; there are concepts called _borrowing, referencing_, and _slicing_, too!

So far, it seems like learning about ownership is more to do with navigating Rust’s memory management solution than it is to learn about the problem it solves. But, instead of taking it as a quirk of the language, the [Rust Book](https://doc.rust-lang.org/book/second-edition/) encourages you to learn about why the language writers were eager create a safer language.

[Read _Ownership in Rust, Part 2_ →](/2018/07/11/ownership-in-rust-part-2)

# References

- [Rust Book](https://doc.rust-lang.org/book/second-edition/)

- [Rust Language Form Post about The Copy Trait](https://users.rust-lang.org/t/the-copy-trait-what-does-it-actually-copy/18730)

