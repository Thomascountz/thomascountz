---
layout: memo
title: Color Strings Refinement
date: '2025-05-27'
tags:
- memo
- ruby
---

```ruby
module Colors
  refine String do
    def red = "\e[31m#{self}\e[0m"
    def green = "\e[32m#{self}\e[0m"
    def yellow = "\e[33m#{self}\e[0m"
    def blue = "\e[34m#{self}\e[0m"
    def magenta = "\e[35m#{self}\e[0m"
    def cyan = "\e[36m#{self}\e[0m"
    def white = "\e[37m#{self}\e[0m"
  end
end

# Usage
using Colors

puts "Hello, World!".green
```
