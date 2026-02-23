---
layout: post
title: "Job Scheduling with at(1)"
subtitle: "The Unix utility that knows when teatime is"
date: 2026-02-22
tags: [journal, shellscript, devtool]
description: "at(1) is a one-off job scheduler that's been hiding in plain sight on Unix systems. Yes, it knows when teatime is."
---

I recently hacked together an ESP-01 and a cheap solar garden lantern[^lantern] so that I can have warm flickering candlelight whenever the mood strikes. For example, by using `at(1)`, I can make teatime[^teatime] just a little more magical:

[^lantern]: Like this: [Lampioncino_solare.jpg](https://commons.wikimedia.org/wiki/File:Lampioncino_solare.jpg), [Antonia Mette, CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0), via Wikimedia Commons

[^teatime]: "...the following keywords may be specified: midnight, noon, or teatime (4pm)..." [at(1) - POSIX specification](https://man7.org/linux/man-pages/man1/at.1p.html)

```bash
$ echo "curl 'http://ember.local/on'" | at teatime
job 42 at Sun Feb 22 16:00:00 2026
```

[`at(1)`](https://man7.org/linux/man-pages/man1/at.1p.html) is a Unix utility for scheduling one-off commands. In the example above, a request to turn on the lantern will be sent at 16:00 local time.

You can verify it's queued with `atq`, and view the job details with `at -c [job]`:

```bash
$ atq
42	Sun Feb 22 16:00:00 2026
```

```bash
$ at -c 42
#!/bin/sh
# atrun uid=502 gid=20
# ...
curl 'http://ember.local/on'
```

Whereas `cron(8)` is used for scheduling recurring jobs, `at` is used for scheduling *one-off* tasks. For example, here are some ways I've found it useful:

**Reminding myself to take a break**

```bash
$ at now + 1 minute <<'EOF'
osascript -e "display dialog \"Stop what you're doing!\" with title \"Take a break\""
EOF
```

**Posting fresh data before a team sync**

```bash
$ echo "curl https://api.example.com/stats | jq . | ~/pipe-to-slack.sh" | at 9:15AM tomorrow
```

**Stopping that debug container I'm probably going to forget about**

```bash
$ echo "docker stop my-debug" | at 1700 friday
```

Although I haven't tried it myself, you can even implement "recurring" jobs by recursively rescheduling the next run at the end of the current job. That said, if such a job fails, the chain breaks silently; there is no built-in retry or alerting like `cron` provides.

```bash
$ cat ~/daily.sh
#!/bin/bash
# Do some work here...
at -f ~/daily.sh 5pm tomorrow

$ at -f ~/daily.sh 5pm
job 43 at Mon Feb 23 17:00:00 2026
```

_This example uses the `-f` flag to tell `at` to read the job from a file._

After a job is executed, its output will be captured and sent to you via local `sendmail(8)`[^force-mail]. On macOS, mail lands in `/var/mail/$USER` by default, and you can read it with `mail(1)`.

[^force-mail]: By default, `at` only sends mail if a job produces output. If you want to receive mail even when there's no output, you can use the `-m` flag.

Keep in mind that `at` snapshots your exported environment (working directory, env vars, umask) from wherever you schedule a job, but it **does not** capture your shell profile (e.g. anything from `.bashrc`, `.zshrc`, etc.). Therefore, it's common practice to use absolute paths and avoid shell-specific features.

## Quick Start

To get started using `at` on macOS, you'll need to manually enable the `atrun(8)` daemon using `launchctl(1)`:

```bash
$ sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist
```

**Command reference:**

`at <time>`
: schedules a job

`atq`
: lists pending jobs

`at -c <id>`
: shows what a job will run

`atrm <id>`
: cancels a job

`at -f script.sh 3pm`
: reads from a file instead of stdin

`at -m`
: sends mail even if there's no output
