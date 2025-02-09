---
layout: memo
title: Interactive jq
date: '2025-01-31'
tags: [memo, jq, fzf, bash]
---

I built an [interactive `jq` TUI](https://gist.github.com/Thomascountz/5ae98a738abb9246b9f7749f53cdddcf) using [`fzf`](https://github.com/junegunn/fzf)!

![](/assets/images/memos/ijq.gif)

I was searching for an interactive jq editor when I came across [this repo](https://github.com/fiatjaf/awesome-jq), which had an intriguing suggestion:

> `echo '' | fzf --print-query --preview "cat *.json | jq {q}"` – An fzf hack that turns it into an interactive jq explorer.

This sent me down a rabbit hole, and I discovered just how incredibly configurable `fzf` is, e.g.:

- You can bind custom keys to execute non-default behaviors:
```bash
--bind=ctrl-y:execute-silent(jq {q} $tempfile | pbcopy)
```

- You can start `fzf` with an initial query:
```bash
--query="."
```

- You can configure `fzf` with different layouts:
```bash
--preview-window=top:90%:wrap
```

- You can add a multi-line header to provide instructions:
```bash
--header=$'ctrl+y : copy JSON\nctrl+f : copy filter\nenter : output\nesc : exit'
```

I wonder how many different TUIs I can create with just `fzf`?

Checkout the code for ijq [here](https://gist.github.com/Thomascountz/5ae98a738abb9246b9f7749f53cdddcf).
