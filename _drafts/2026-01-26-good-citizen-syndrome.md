---
layout: post
title: Good Citizen Syndrome
date: '2026-01-26'
description: ''
tags: [teams, process, leadership]
---

To explain what _Good Citizen Syndrome_ is, let me tell you about something that _didn't_ happen...

> Thousands of customers _didn't_ experience service outages, and on-call engineers _weren't_ paged, because packets _weren't_ dropped by cache instances that _weren't_ starved of network bandwidth, since ElastiCache Memcached Reserved Instances _weren't_ downsized right before renewal, because a last-minute cost-optimization proposal shared in Slack _wasn't_ simply greenlit and therefore the change _didn't_ make it to production.

None of it happened because a group of Good Citizens, with the expertise and willingness to help, happened to be there.

## _Good Citizen Syndrome_ is what happens when engineering leaders—often unwittingly—replace good reliability engineering with good reliable engineers.

Engineers who are technically skilled, proactive, and care deeply about the user experience of the systems they build, often step up to fill gaps in process, governance, and oversight. This lulls an organization into a false sense of security, where near misses go unreported and systemic issues are prevented from becoming incidents.

The danger is that _Good Citizen Syndrome_ makes system reliability practices invisible, and therefore it becomes difficult to measure, manage, and make informed decisions around system behavior, health, and risk. Karl Weick explains this phenomenon by calling reliability a "dynamic non-event."

> Reliability is dynamic in the sense that it is an ongoing condition in which problems are momentarily under control due to compensating changes in components...people often don't know how many mistakes they could have made but didn't, which means they have at best only a crude idea of what produces reliability and how reliable they are... Operators see nothing and seeing nothing, presume that nothing is happening.[^weick]

[^weick]: Weick, K. E. (1987). Organizational culture as a source of high reliability. California Management Review, 29(2), 112-127.

Complex systems run without incident. Because nothing bad happens, stakeholders accept this as meaning nothing is being done; they mistake the absence of failure for the presence of stability within the system. Meanwhile, _Good Citizens_ are constantly firefighting, patching holes, and preventing small issues from becoming big ones.


## Get to know what your best engineers _actually_ do, rather than what you _think_ they do.

Organizations do require _Good Citizenship_, but as an engineering leader, you have to intentionally prevent it from resulting in _Good Citizen Syndrome_—you must understand how your organization operates beyond what your customers and users see.

John Gall calls this the "functionary's falsity":

> ...if you go down to Hampton Roads or any other shipyard and look around for a shipbuilder, you will be disappointed. You will find—in abundance—welders, carpenters, foremen, engineers, and many other specialists, but no shipbuilders... Clearly, they are not in any concrete sense building ships. In cold fact, a SYSTEM is building ships, and the SYSTEM is the shipbuilder.[^gall]

[^gall]: Gall, J. S. (1975). Systemantics: How systems really work and how they fail. New York: Times Books.

Your organization is a system, and its reliability is an emergent property of that system—not the sum of individual heroics. If a carpenter keeps finding bad welds, you have two choices: rely on her to keep catching them, or develop a system for managing weld quality. The first is convenient. The second is your job.

When a worker's role says "carpenter" but you discover she's also inspecting welds—that's your signal. You have _Good Citizen Syndrome_. The fix isn't to punish the carpenter or tell everyone to ignore problems outside their job description. It's to leverage your _Good Citizens_ as guides: they're showing you exactly where the system has gaps.

Which brings us back to where we started. Thousands of customers _didn't_ experience outages because a group of _Good Citizens_ caught a bad resize proposal in Slack. There was no incident—but there was a near-miss.

Did the engineering leader see this and think: _we should rethink how we approve resize requests, since this one almost got through and we got lucky_?

Or did they just feel relieved and move on?

That's the difference between managing a system and getting lucky. And luck, eventually, runs out.

To explain what _Good Citizen Syndrome_ is, let me tell you about something that _didn't_ happen...

> Thousands of customers _didn't_ experience service outages, because packets _weren't_ dropped by cache instances that _weren't_ starved of network bandwidth, since ElastiCache Memcached Reserved Instances _weren't_ downsized right before renewal, because a last-minute cost-optimization proposal shared in Slack _wasn't_ simply greenlit, and therefore the change _wasn't_ applied to production.

On-call engineers _weren't_ paged and a customer post-mortem _wasn't_ scheduled because someone happened to see something and say something. _This isn't a resiliency strategy, this is luck._

**Good Citizen Syndrome is what happens when engineering leaders—often unwittingly—substitute good reliability engineering with good reliable engineers.**

Skilled engineers who care about reliability constantly step up to fill gaps in process, governance, and oversight, in order to keep systems running. While this _can_ be a sign of a mature organization, latent conditions remain in our systems if leadership doesn't engage with identifying their root conditions.

In his book about organizational culture, Karl Weick calls reliability a "dynamic non-event;" a phrase which underscores the false sense of safety _good_ reliability can cause.

> Reliability is dynamic in the sense that it is an ongoing condition in which problems are momentarily under control due to compensating changes in components... Operators see nothing and seeing nothing, presume that nothing is happening.[^weick]

[^weick]: Weick, K. E. (1987). Organizational culture as a source of high reliability. _California Management Review_, 29(2), 112-127.

When reliability engineering is done well, nothing bad happens. And, when nothing bad happens, it can look very similar to nothing being done at all! However, in reality, it's the exact opposite: **it takes a lot of work to make nothing happen!**

After _Good Citizen Syndrome_ is identified, there is but one cure: close calls should be diagnosed and addressed as failures of our organization.

> Effective risk management depends crucially on establishing a reporting culture. Without a detailed analysis of mishaps, incidents, near misses, and “free lessons,” we have no way of uncovering recurrent error traps or of knowing where the “edge” is until we fall over it.[^reason]

[^reason]: Reason J. (2000). Human error: models and management. 10.1136/bmj.320.7237.768.

_Good Citizen Syndrome_ extends beyond reliability engineering. Maintenance, KTLO, dependency upgrades, and other non-feature work are all vulnerable to the Syndrome. **Address it like your customers depend on it—because they do.**
