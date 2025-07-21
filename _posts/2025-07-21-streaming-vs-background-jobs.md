---
layout: post
title: Event Streaming vs Background Jobs
date: '2025-07-21'
tags:
- system design
- streaming
- background jobs
---

I was recently asked the question:

> Can we just use ActiveJob instead of Kafka?

I think there may have been a misunderstanding of the differences between event streaming platforms (like Apache Kafka) and background job systems (like ActiveJob).

At their core, they both solve problems related to scaling. But, we can think of one as managing a **log of events**, and the other as managing a **to-do list**.

## Log of Events

Streaming platforms like Kafka are designed for decoupling components which all need to be informed about specific events and when they happened, using a **publish-subscribe** model.

To do this, **message brokers** capture **events** from various sources called **producers** (or **publishers**), and broadcast them as a continuous **stream** (or **log**).

These events can then be read by one or more **consumers** (or **subscribers**), each using the data for its own purpose.

This is useful for scenarios where different consumers need to react differently to the same event. For example, one consumer might record the event data in a data lake, another might update a search index, and yet another might trigger an alert, all in response to the same event.

Each consumer can read the log independently of each other. The log of events is often **durable**, meaning they're stored for a given period of time, allowing some consumers to react in near real time, while others choose to read at their leisure.

## To-Do List

Background job systems, like Resque or SolidQueue, are built for **offloading work** from an application's main process, using a **queue-based** model.

A **job** acts like an instruction for work to be done, most often as soon as possible. It's placed on a **queue** by a job **orchestrator** (or **scheduler**).

**Workers** continually check the queue for a job to do. When the worker finds one, it  **consumes** and processes it such that no other worker picks it up.

This is useful for tasks that are too resource-intensive to run in the main application process, but that you'd otherwise like to happen sequentially.

For example, when a user uploads a new avatar, you may want to resize the image and store it in a CDN without blocking the application server from responding to new requests.

Workers are interchangeable, which allows for **load balancing** between them and **horizontally scaling** additional capacity when needed. Background jobs can also be **durable**, allowing them to be retried if a worker crashes or a job fails.

## The Confusion

The overlap between these two systems is that they both deal with **asynchronous processing** and **scaling**. However, if you are using a Kafka consumer as a background job worker, you are not leveraging the advantages of event streaming that it provides.

In particular, the benefit of allowing multiple consumers to react differently to the same event is lost when you design for only one consumer to process the event like a background job worker would.

Additionally, platforms like Kafka often come with the cost of increased complexity, meaning, although you can use Kafka as a background job system, you may not have a use case that justifies the overhead.

## The Conclusion

To summarize the differences, I give you the following analogy drawn from my years in the dining industry.

### Dinner Service is like an Event Stream

Diners (producers) place orders (events) to different servers (distributed brokers). The same order is used for different things (consumers): point-of-sale systems use it for bill calculations, the kitchen uses it to expedite, and front-of-house staff uses it to know where and when to seat guests. If a new inventory system is added, it can use the orders to predict when purchases should be made, without disrupting the existing system. 

Each order is placed at a specific time and is used differently by different consumers.

### Morning Prep is like a Background Job System

Each station in the kitchen (orchestrator) prepares a list of tasks (jobs) to be completed before service starts. Each task is picked up sequentially (consumed) by the next available prep cook (worker) until the queue is empty. If the weekend was rather busy, additional staff can be scheduled for prep on Monday to replenish the stock. 

Everyone works through a different prep task as soon as they can, removing it from the list as they go.


