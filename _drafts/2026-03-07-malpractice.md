---
layout: post
title: ""
subtitle: ""
date: "2026-03-07"
description: ""
tags: [decision-making, systems]
---

Malpractice
I find this an interesting casestudy. The subtitle, "A Terraform command executed by an AI agent wiped the production infrastructure...", pushes responsibility for deleting a production database onto an AI agent, only to then use the passive voice to fault a command which executed. 

I bet you're thinking there was some YOLO-ing going on (I certainly did), but just you wait! 

Before continuing, I want to say that I don't normally criticize other people's blog posts. In fact, I have a lot of respect for this author sharing such a detailed recounting of such a difficult situation. And in the end, they restored their systems and came away with some good ideas to avoid this kind of thing in the future. I focus on this particular incident, not because it's so egregious, but because I believe it represents a significant trend.

So, if Claude wasn't dangerously skipping permissions, what happened?

...[Claude] output: "...Since the resources were created through Terraform, destroying them through Terraform would be cleaner and simpler than through AWS CLI.” 

That looked logical: if Terraform created the resources, Terraform should remove them. So I didn’t stop the agent from running terraform destroy.

The author read Claude's output and believed it looked logical. The mistake was ostensibly "not stopping the agent from running the command." Not the myriad other things that led there, not, "I pressed enter," no! The root cause of the database existing at one moment, and then not existing at the next moment, was having not prevented it from doing that. 

To me, this is like someone crashing their car and saying:

An instruction for the car to turn left given by GPS wiped out the old oak tree... "The forest is on the left, so turn left." 

That seemed right: since I was driving to the forest, and the forest was on the left, the car should turn left. So, I didn't stop the car from turning left into the tree.

I know it sounds ridiculous, and maybe I am being facetious and harsh. Please forgive me and continue reading without dissecting the strawman that is my analogy...

What is the real problem? 

The author themself, concludes with a list of things that went wrong and what they've done to improve upon them. I respect and agree with all of of them. However, the biggest problem in my opinion—and one that is often missing from the discourse around these sorts of postmortems—is the engineer's lack of awareness of how much their mental model is wrong, their unknown-unknowns.

We are all well aware that AI can be confidently wrong, but we are all increasingly comfortable forgetting that, so too can we.  

A lack of confidence is often what signals us to fallback to safer practices. It's what makes us look both ways before crossing the road, reread the recipient's email address before pressing send, and check our cameras before joining a video call. A lack of confidence is the perception that a situation requires more knowledge, skill, or ability than we currently have. 

As software engineers, it's our job to use that judgment as a factor in our decision-making, especially in situations that carry risk. 

Increasing one's confidence used to be hard-won. It would come by way of consistent cycles of challenge and practice, exercised over human-scale timeframes. And it required dedicated knowledge-keeping, resulting in system designs that could fit in one's head, a ceaseless ritual of once-sacred (though often-flawed) code review, and a hierarchical structure of titles, which roughly mapped the distribution of institutional confidence. 

Confidence, like trust, was earned and tended to. Not just by people, but also in the artifacts they built. 

But now, many engineers have become comfortable numbing their lack-of-confidence signals with the pull of a slot machine lever.
