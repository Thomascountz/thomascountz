---
layout: post
title: "The Blog About Passive Voice Was Published"
subtitle: "Let the outcomes do the talking"
date: '2026-02-08'
description: 'In this blog post, I summarize my preference for passive voice when writing reports, updates, and other high-density information.'
tags: [process]
---

Hi there. Let's jump right in: 

1. What did you do yesterday? 
2. What will you do today? 
3. Any blockers? 

Recognize those? These are the three core questions of a daily standup. A type of synchronization meeting bourne out of Scrum, ported to Agile and Extreme Programming, and has now wicked into every thread and fiber of software delivery teams. 

The purpose of a standup is to deliver relevant news with your peers and to use that information to coordinate your shared goals. In fact, a large portion of a software engineer's job is to manage this (mis)communication. 

To that end, I recently discovered how effective using passive voice can be in standup—and any other situation where I'm delivering new information to a low-context audience. Not only has it made my communication better, it has begun to change the way I _think_ about my work and how I collaborate with others.

## ~~What did you do~~ What has changed since yesterday?

Only a maximum of two people (you and your manager) may ever care about what _you_ personally did on any given day. Any discussions about that is be better suited for a one-on-one. 

The majority of your update's audience is concerned about what has _changed_ since the last update. 

What this means in regards to passive voice is that we'd do well to remove the _subject_ from both the question and answer, and simply leave the _object_.

Let's take "What did you do yesterday?" as an example:

> Yesterday, I paired with the Jinteki team who wrote a patch for the VPN-issue with Beanstalk's rate limiter and asked if I could test it. I think it could be extracted into a library, since it will at least be useful for Heinlein as well, and I started looking into that.

Like the question itself, the answer if full of active voice: "_I_ paired...," "The _Jinteki team_ wrote/asked," "

Now, here's the same information, but with the framing of "What has changed since yesterday?"

> Yesterday, a patch to resolve the VPN-relate bug in Beanstalk's rate limiter was tested, deployed, and verified. Initial tests show that Heinlein (and maybe others) could benefit from the same patch.
