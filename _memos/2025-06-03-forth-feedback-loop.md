---
layout: memo
title: Forth Feedback Loop
date: '2025-06-03'
tags:
- memo
- forth
---

Inspired by [Andreas Wagner's `ecr` word](https://youtu.be/mvrE2ZGe-rs?si=xtAowOuaxtU9B3_D&t=1060), I created the word `go`:

```factor
\ go.fs

: go#empty  s" ---marker--- marker ---marker---" evaluate ;
: go#open   s" vim my_project.fs" system ;
: go#run    s" my_project.fs" included ;

: go go#empty go#open go#run ;

marker ---marker---
```

`marker ---marker---` defines a special word: `---marker---`
  * When executed, it makes Forth forget all definitions made after it (including itself).

The `go` word orchestrates an edit-reload cycle:
*   `go#empty` is the clever bit.
    * It `evaluate`-s the string `"---marker--- marker ---marker---"`.
    * This first runs the *existing* `---marker---` (clearing definitions from the previous load of `my_project.fs`).
    * Then it defines a *new* `---marker---` at the now-empty top of the dictionary, priming it for the next cycle.
*   `go#open` uses `gforth`'s `system` to open `my_project.fs` in vim.
*   `go#run` uses `included` to load the freshly edited `my_project.fs`.
