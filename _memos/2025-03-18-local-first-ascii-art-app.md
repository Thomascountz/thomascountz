---
layout: memo
title: "Cascii: ASCII Diagram Tool"
date: '2025-03-18'
tags:
- memo
- tools
---

<img src="/assets/images/memos/monolith_b_ascii_diagram.png" style="max-width:280px" alt="ASCII diagram from my talk, 'From Legacy to Latest: How Zendesk Upgraded a Monolith to Rails 8.0 Overnight' created using Monodraw and Keynote">


Today, I discovered [https://cascii.app/](https://cascii.app/), "...one of the few well-equipped ASCII diagram builders freely available on the internet."

I've fallen in love with ASCII (Unicode) diagramming when creating the slides for my most-recent talk, [From Legacy to Latest: How Zendesk Upgraded a Monolith to Rails 8.0 Overnight](https://www.youtube.com/watch?v=kgVgcNtN5mc). For those, I used a tool called [Monodraw](https://monodraw.helftone.com/), is most capable tool for the job that I've found.

How does Cascii stack up?

A key advantage is its portability: you can use Cascii directly in your browser (it's a [single HTML file, no less!](https://github.com/casparwylie/cascii-core/blob/main/cascii.html)) and export your drawings as URLs, making sharing, backups, and version control incredibly simple.

Additionally, it has a number of things going for it that other tools lack:

* **Dark mode!**
* Depth stacking and layering
* Anchor points for connection lines
* Both ASCII and Unicode modes

However, Cascii currently lacks a few features that I've come to depend on in Monodraw:

* Aligned text inside shapes
* Multiple shape border merging
* Shape fill opacity for overlap layering
* An arbitrary single-character pencil tool
* Visible grid and alignment snapping

Given that [Cascii is open sourced](https://github.com/casparwylie/cascii-core/), I forsee a lot of these missing features coming in the near future.
