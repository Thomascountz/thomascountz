---
layout: post
title: "Job Scheduling with at(1)"
subtitle: "The Unix utility that knows when teatime is"
date: 2026-02-22
tags: [journal, shellscript]
description: "at(1) is a one-off job scheduler that's been hiding in plain sight on Unix systems. Yes, it knows when teatime is."
---

I recently hacked together an ESP-01 and a cheap solar garden lantern so that I can have warm flickering candlelight whenever the mood strikes. For example, by using `at(1)`, I can make teatime[^1] just a little more magical:

[^1]: "...the following keywords may be specified: midnight, noon, or teatime (4pm)..." [at(1) - Linux man page](https://linux.die.net/man/1/at)

```bash
$ echo "curl 'http://ember.local/on'" | at teatime
```

[`at(1)`](https://man7.org/linux/man-pages/man1/at.1p.html) is a Unix utility for scheduling one-off commands. In the example above, a request to turn on the lantern will be sent at 4pm.

Whereas `cron(8)` is used for scheduling recurring jobs, `at(1)` is used for scheduling "do-this-thing-ONCE-at-some-point-in-the-future" kind of jobs, for example:

Scheduling a server restart during off-hours:

```bash
ssh admin@server 'echo "sudo systemctl reboot" | at 02:00'
```

Grabbing fresh data before a sync with the team:
```bash
echo "curl api.example.com/stats | jq . | ~/pipe-to-slack.sh" | at 9am monday
``` 

Stopping that debug container you're likely going to forget:
```bash
echo "docker stop my-debug" | at now + 2 hours
```

You can even implement cron-like recurring jobs by executing `at` at the end of a job. (Using `-f` to read from a file makes this even easier to manage):

```bash
$ cat ~/daily.sh
#!/bin/bash
# Do some work here...
at -f ~/daily.sh 5pm tomorrow

$ at -f ~/daily.sh 5pm
```

On macOS, the `atrun(8)` daemon is disabled by default. You have to enable it using `launchctl`:

```bash
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
```

`at(1)` captures the entire shell environment from where you schedule the job. This means that when `atrun(8)` executes your job, it runs with your working directory, env vars, umask, etc.

When a job produces output (or you use the `-m` flag), it will be sent to you via local `sendmail(8)`. On macOS, mail lands in `/var/mail/$USER` by default, and you can read it with the `mail` command. 

Other useful bits:

- `atq` lists pending jobs
- `at -c <id>` shows what a job will run 
- `atrm <id>` cancels a job 
- `at -f script.sh 3pm` reads from a file instead of stdin
- `batch` is a sibling that runs jobs when system load is low rather than at a specific time
