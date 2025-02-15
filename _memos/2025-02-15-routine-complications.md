---
layout: memo
title: Routine Complications
date: '2025-02-15 12:08:18 +0100'
tags:
- memo
---

In [_A Life-Saving Checklist_](https://archive.is/0H188), author Atul Gawande describes a patient suffering from an infection introduced by medical equipment. These "line infections" are so common, they're said to be a _routine complication_.

In medical practice, a routine complication refers to an **adverse event or difficulty that is known to occur with some regularity in association with a particular procedure or treatment**. These complications are _expected_ in the sense that they are well-documented and occur with a known frequency, **allowing healthcare providers to anticipate and manage them effectively**.

In other domains, such as software development, it is useful to identify routine complications inherent to various operations, and understand both their potential for happening and their potential negative impacts.

As an example, during incident response, if standard operating procedure (SOP) includes restarting a web server, routine complications to be understood include: accidentally restarting a healthy server (misdiagnosis), executing a restart incorrectly (human error), cutting off further observations of the issue before it’s fully understood (state evaporation), and encountering unexpected dependencies that cause cascading failures (hidden coupling).

Just because restarting a web server carries with it these potential issues, doesn't mean we should shy away from the tried-and-true "turn it off and on again" procedure (every operation carries risk after all). Instead, we should manage routine complications by understanding them honestly, preparing for them openly, and being blameless when they happen.
