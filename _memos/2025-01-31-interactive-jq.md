---
layout: memo
title: Interactive jq
date: '2025-01-31'
tags: [memo, jq, fzf, bash]
---

I built an [interactive `jq` TUI](https://gist.github.com/Thomascountz/5ae98a738abb9246b9f7749f53cdddcf) using [`fzf`](https://github.com/junegunn/fzf)!

![](https://private-user-images.githubusercontent.com/19786848/408505499-9068ddf4-702f-4f54-9c7a-3ce6ef2baae8.gif?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzkxMjM5NTYsIm5iZiI6MTczOTEyMzY1NiwicGF0aCI6Ii8xOTc4Njg0OC80MDg1MDU0OTktOTA2OGRkZjQtNzAyZi00ZjU0LTljN2EtM2NlNmVmMmJhYWU4LmdpZj9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTAyMDklMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwMjA5VDE3NTQxNlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWNhMWVjMGRjZGQ5ZTA4NTA3NjQ0OGQ4OGJkNzM5MzliNWE1MjZmY2YwOGRkNzQ2MWFmZjU0NTE5MTNlMGQ0ODYmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.qdRNikzI75S9HPmLlHvTJssma_ovGiOMHdhhLthp6Fk)

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
