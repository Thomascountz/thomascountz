---
layout: memo
title: Ruby CLI Progress Bar
date: '2025-02-08'
tags: [memo, ruby, cli]
---

```ruby
def print_progress(title, total, current_progress, bar_width: 50)
  progress_pct = (current_progress.to_f / total) * bar_width
  printf("\r#{title}: [%-#{bar_width}s ] -- %s", "▤" * progress_pct.round, "#{current_progress}/#{total} ")
end

# Usage
1.upto(10) do |i|
  print_progress("Here we go!", 10, i)
  sleep 0.2
end;print("\n")

# Output Example:
# Here we go!: [▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤▤                ] -- 7/10
```
