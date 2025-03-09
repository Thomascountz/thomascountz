---
layout: memo
title: 'Ruby Bug #21117'
date: '2025-02-20'
tags:
- memo
- ruby
---

### tl;dr
1. Numbered block params (`_1`, `_2`, etc.) are reserved and read-only, while `it` (the new block param in Ruby 3.4) has different mutation rules for compatibility.
2. Using combined assignment operators (e.g. `+=`, `&&=`), numbered block params could be overwritten without error due to a discrepancy between parse.y and Prism (Ruby's default parser since 3.3).
3. A patch has been applied to Prism in Ruby 3.4.2 to explicitly check for writes to numbered params via combined assignment operators.

### The Bug

In Ruby, block-local numbered parameters (`_1`, `_2`, etc.) provide a concise way to reference block arguments without explicit naming. They have received renewed attention recently with the [introduction of the `it` parameter](https://bugs.ruby-lang.org/issues/18980) in Ruby 3.4.

Though they serve a similar purpose, numbered parameters are designed to be read-only, while `it` is intentionally mutable for backward compatibility reasons.

In [Bug #21117](https://bugs.ruby-lang.org/issues/21117), radarek (Radosław Bułat) identified inconsistencies in how Ruby handles assignments to `_1` and `it`. Most concerning was that `_1` could be modified in specific cases, violating its intended immutability.

Direct assignment correctly raises `SyntaxError`:
```ruby
irb(main):001> [1, 2, 3].each { _1 = _1 + 1; p _1 }
<internal:kernel>:168:in 'Kernel#loop': (irb):1: syntax error found (SyntaxError)
> 1  | [1, 2, 3].each { _1 = _1 + 1; p _1 }
     |                  ^~ Can't assign to numbered parameter _1
```

However, combined assignment operators work without error:
```ruby
irb(main):002> [1, 2, 3].each { _1 += 1; p _1 }
2
3
4
=> [1, 2, 3]
```

The root cause was an implementation difference between Prism (Ruby's default parser since 3.3) and parse.y. Prism failed to enforce numbered parameter immutability for combined assignment operations, while the legacy parse.y parser correctly rejected these operations:

```ruby
# $ ruby --parser 'parse.y' -e 'binding.irb'

irb(main):001> [1, 2, 3].each { _1 += 1; p _1 }
<internal:kernel>:168:in 'Kernel#loop': _1 is reserved for numbered parameter (SyntaxError)
```

### The Fix

Commit [d3fc56d](https://github.com/ruby/ruby/commit/d3fc56dcfa7b408cc3b6788efad36fd8df3e55da) ports Kevin Newton's (kddnewton) fix from Prism. The update adds explicit checks when parsing combined assignment tokens (`PM_TOKEN_#{op}_EQUAL`) to reject any attempts to modify numbered parameters.

Simplified code snippet from the fix:

```c
// In prism.c:
switch (token.type) {
  // Cases for all combined assignment operators
  case PM_TOKEN_PIPE_PIPE_EQUAL:
  // ...other operator cases...
  case PM_TOKEN_PLUS_EQUAL:
  case PM_TOKEN_SLASH_EQUAL:
  case PM_TOKEN_STAR_EQUAL:
  case PM_TOKEN_STAR_STAR_EQUAL:
    switch (PM_NODE_TYPE(node)) {
        case PM_LOCAL_VARIABLE_READ_NODE: {
            // Check if we're trying to modify a numbered parameter
            if (pm_token_is_numbered_parameter(node->location.start, node->location.end)) {
                PM_PARSER_ERR_FORMAT(parser, node->location.start, node->location.end,
                                     PM_ERR_PARAMETER_NUMBERED_RESERVED, node->location.start);
                parse_target_implicit_parameter(parser, node);
            }
        }
        // ...other cases...
    }
    // ...
}
```

### What About `it`?

The `it` keyword intentionally has different behavior than numbered parameters for backward compatibility. While direct assignment (e.g. `tap { it = 2; p it }`) is currently allowed to avoid breaking legacy code, Ruby core developers encourage treating `it` as read-only for consistency with numbered parameters.
