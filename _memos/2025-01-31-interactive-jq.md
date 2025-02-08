---
layout: memo
title: Interactive jq
date: '2025-01-31'
tags: [memo, jq, fzf, bash]
---

I built  (Yet another) interactive jq, but it's a bash script using fzf!


I was searching for an interactive jq editor when I came across this repo, which had an intriguing suggestion for a CLI using only `fzf`: `echo '' | fzf --print-query --preview "cat *.json | jq {q}`

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

I wonder how many different TUIs I can create with just `fzf`!

Checkout the code for ijq [here](https://gist.github.com/Thomascountz/5ae98a738abb9246b9f7749f53cdddcf#comments).
