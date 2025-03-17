---
layout: memo
title: Run Commands on File Change
date: '2025-03-17'
tags:
- memo
- tip
---

I use [`entr`](https://github.com/eradman/entr) to run commands automatically when files change. Here's how I use it to run tests.


Use:
```shell
ls lib/* spec/* | entr -c bin/test
```

Notes:
- Install: [`brew install entr`](https://formulae.brew.sh/formula/entr#default)
- `-c` clears the screen before running the command
- `find lib spec -name '*.rb'` works the similarly to `ls`, but I can't always remember the syntax
- `git ls-files` is another option for watching tracked files in a repo
- [`watchexec`](https://github.com/watchexec/watchexec) is an alternative to `entr`, known for being more feature-rich
