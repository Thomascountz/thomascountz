---
layout: post
title: My Experience Learning Zig
date: '2025-12-19'
tags: 
  - journal
  - zig
---


> ZIG VERSION: 0.16.0-dev.1484+d0ba6642b

Over the course of November, I began learning Zig in preparation for the [Advent of Code 2025](https://adventofcode.com/2025). Other than a few [excusions in to Rust](/tag/rust/), I haven't worked extensively with a systems-level language before—I'm used to a garbage collector handling memory and a virtual machine interpreting my code at runtime. 

A few things really excited me about Zig, and I want to share my thoughts around those specific features.

## Arbitrary Integer Sizes

`u8`, `i16`, `u19`, `i42`... all of these are valid integer types in Zig. One of Zig's big promises isn't just "memory safety," but "explicit memory management." This surfaces in the type system where you can specify _exactly_ how much space an integer should be given.

At first, this just seemed like a weird quirk, however it reinforced the intention of Zig to give programmers explicit control over optimizations, which are normally hidden in the compiler.

## Comptime

Ruby is well-known for its dynamic metaprogramming, which lets you write code that defines code at runtime. Zig also supports metaprogramming, but does so when it's compiling your code.

This manifests in Zig's reflection capabilities: you can only inspect types at comptime. In Ruby, you might have method overloading where you check the type (class) of an argument and branch accordingly. In Zig, we do this via method _overloading_ at comptime:

```zig
fn printValue(comptime T: type, value: T) void {
    if (T == i32) {
        std.debug.print("Integer: {}\n", .{value});
    } else {
        std.debug.print("Unknown type\n", .{});
    }
}
``` 

Here, we explicitly annotate the `T type` parameter as `comptime`, which allows the Zig compile to define a specialized version of `printValue` for each type `T` used at compile time. 

## Switch Exhaustiveness and Unreachable

Zig requires exhaustive handling of all possible cases in `switch` statements. This is a huge boon for any type of property-based testing or fuzzing, as the compiler will ensure the behavior across the entire state space is defined.

If all valid invariants are considered the "positive space," then we must either constrain the input space to just that domain, or handle the "negative space" explicitly. To handle the negative space, Zig provides the `unreachable` assertion keyword, which explicitly indicates that a certain code path should never be executed.

As a trite example, consider a function which accepts an array of `u8` values, but only processes values up to `250`. We can use `unreachable` to handle the invalid input space:

```zig
fn processArray(arr: []const u8) void {
    for (arr) |value| {
        switch (value) {
            0..=250 => {
                // Process valid value
            },
            else => unreachable, // Handle invalid input
        }
    }
}   
``` 

In Zig, `unreachable` is an assertion to the compiler (and other programmers) that the array will never contain values outside the `0..=250` range.

## Type System Fun for Dynamic Language Programmers

There's a lot of fun to be had with a type system which I've come to appreciate: unions, enums, and optional come to mind. Here's a quick speedrun:

### Unions
