---
layout: post
title: Debouncing API Calls
date: '2025-07-02'
tags: [javascript, api, performance]
---

{% include js_debounce/debounced_input.html %}

## Hardware

The term "debouncing" originates from electronics (at least that's where I first came across it). When you press a physical button or flip a switch, its metal contacts don't connect cleanly just once; they "bounce," opening and closing rapidly, creating multiple pulses of current as the circuit connects and disconnects.

Although this happens on the order of milliseconds, filtering the rapid switching is necessary to prevent other components from misinterpreting the bounces as intentional signals. Debouncing in hardware ensures that only a single, clean signal is sent when the button is pressed.

## Software

In software, we hit this same problem.

Take search bars, for example. They often fire off an API call on every keystroke to give search results to users with broken enter keys.

With a typing speed of around 200 characters-per-minute (3.33 characters-per-second), a user searching for "parachute pants" could trigger 16 API calls in about 5 seconds—and that's assuming they don't make any typos.

We can't possibly know which of those 16 API calls actually improve the user experience, but if I had to guess, search suggestions are most effective when presented after a natural pause in typing—not during every keystroke.

## Debouncing with Delays

This `debounce` function uses `setTimeout` to delay the execution of a callback.

```javascript
function debounce(callback, delay) {
  let timerId;
  return (...args) => {
    clearTimeout(timerId);
    timerId = setTimeout(() => {
      callback(...args);
    }, delay);
  };
}
```

If the returned function gets called again before the timer finishes, it clears the previous timer and starts a new one. This resets the wait time and prevents callbacks from executing until there has been a pause in calls for the specified delay.

This is exactly what the demo above does. It waits for you to stop typing for a set number of milliseconds before updating the output field with your input.

## Delays and Cancellations

For input-triggered API calls (like the search bar example) we can take this further by combining debouncing with request cancellation.

When the user stops typing in the search bar, the app waits until after a delay (similar to our earlier debounce implementation) before making an API call to fetch search suggestions.

{% include js_debounce/cancelled_fetch.html %}

If, however, the user begins typing again _before_ the fetch resolves, we need a way to throw away the request. This is because, by the time we would receive a response, the user has already moved on and started searching for something else.

So, before making any new API requests, we first cancel the previous `fetch`, using the `AbortController` API.


```javascript
function debouncedFetch(delay) {
  let timerId;
  let controller;

  return (...args) => {
    clearTimeout(timerId);
    if (controller) {
      controller.abort();
    }

    controller = new AbortController();
    const signal = controller.signal;

    timerId = setTimeout(async () => {
      const response = await fetch(`https://example.com`, {
        signal: controller.signal
      });
      // Handle the response here
    }, delay);
  };
}
```

This `debouncedFetch` function works in three steps.

First, it clears any pending timer and cancels any in-flight request. If there's no previous request (like on the first call), the latter step is skipped.

Then, it creates a new `AbortController` and extracts its `signal`. This signal acts like a remote control that can cancel the upcoming `fetch` request at any time. This works because the `fetch` API supports aborting requests using an `AbortSignal`.

Finally, it starts a new timer. When the timer expires, it calls `fetch`. And when `fetch` resolves, we handle the response as needed.

So, as before, if the user types again before the timer expires, the timer is restarted before a new `fetch` request is made.

In addition to this, if the user types again _while the previous `fetch` is still in progress_, that request is cancelled, the new input is debounced, and then finally, a new `fetch` request is made with the latest input.


