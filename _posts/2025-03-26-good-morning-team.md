---
layout: post
title: Good Morning, Team!
date: "2025-03-26"
tags:
  - journal
  - ruby
---

Every so often, I like to write a Ruby script that says good morning to my team in a fun way. Here is the one I made this morning which mimics the famous [bouncing DVD logo](https://bouncingdvdlogo.com/).

<img src="/assets/images/journal/good_morning_team.gif" style="max-width:480px" alt="A colorful 'Good Morning, Team!' text bouncing around the terminal window">
  
{: .wrap-it}
```ruby
require "io/console"
greeting = [71, 111, 111, 100, 32, 77, 111, 114, 110, 105, 110, 103, 44, 32, 84, 101, 97, 109, 33].map(&:chr).join
colors = ["\e[31m", "\e[33m", "\e[32m", "\e[36m", "\e[34m", "\e[35m"]
rows, columns = begin
  io.console.winsize
rescue
  [24, 80]
end
g_width = greeting.size
g_height = 1
x = rand(columns - g_width)
y = rand(rows - g_height)
dx = 1
dy = 1
frame = 0
loop do
  print "\e[h\e[2j"
  puts "\n" * y
  color = colors[frame % colors.size]
  print(" " * x + color + greeting + "\e[0m")
  sleep 0.05
  if (x + dx < 0) || (x + g_width + dx > columns)
    dx = -dx
    frame += 1
  end
  if (y + dy < 0) || (y + g_height + dy > rows)
    dy = -dy
    frame += 1
  end
  x += dx
  y += dy
  sleep 0.25
end
```
