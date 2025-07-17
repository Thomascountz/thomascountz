---
layout: post
title: Chrome's SSL Bypass Cheatcode
date: '2025-07-17'
tags:
- memo
- chrome
- security
---

## This is Unsafe

If you type `thisisunsafe` on a Chrome SSL error page, Chrome will bypass the error and load the page for you.

<video src="/assets/images/thisisunsafe.mp4" controls loop muted playsinline></video>

Try it yourself here: [https://expired.badssl.com/](https://expired.badssl.com/)

There's no textbox to type into, just type `thisisunsafe` blindly with the page in focus.

> TIP: To revert the bypass, click the "Not Secure" button in the URL bar and then click "Turn on warnings."

---

## History of the Bypass Code

I discovered Chrome SSL error bypass code while debugging SSL issues. I was surprised that something like that existed, and was flooded with of memories of entering `↑ ↑ ↓ ↓ ← → ← → B A` into my PS1 as a kid (see  _[Konami Code](https://en.wikipedia.org/wiki/Konami_Code)_).

Curiosity got the better of me, and, like Tomb Raider searching for ancient artifacts, I started digging into the history of the bypass code in Chromium.

Here's what I found.


### Danger (2014)

The bypass code was originally "`danger`," and was added to Chromium in 2014 as part of a larger piece of work to remove duplication between `chrome/browser/resources/safe_browsing/` and `chrome/browser/resources/ssl/`.

> Safe Browsing HTML/JS is in:
> chrome/browser/resources/safe_browsing
>
> And SSL HTML/JS is in:
> chrome/browser/resources/ssl
>
> But they all essentially use the same code. Merge into a single folder and remove redundancy.
>
> [Aug 11, 2014 18:03UTC - Chromium Issue #41125304](https://issues.chromium.org/issues/41125304)

Why it was added is not clear to me, but presumably it was to allow developers to more easily bypass SSL errors during the raise of SSL-everywhere.

[https://codereview.chromium.org/480393002/patch/60001/70017](https://codereview.chromium.org/480393002/patch/60001/70017)
```js
/*
 * This allows errors to be skippped [sic] by typing "danger" into the page.
 * @param {string} e The key that was just pressed.
 */
function handleKeypress(e) {
  var BYPASS_SEQUENCE = 'danger';
  if (BYPASS_SEQUENCE.charCodeAt(keyPressState) == e.keyCode) {
    keyPressState++;
    if (keyPressState == BYPASS_SEQUENCE.length) {
      sendCommand(CMD_PROCEED);
      keyPressState = 0;
    }
  } else {
    keyPressState = 0;
  }
}
```

### Bad Idea (2015)

A year later, in 2015, the `BYPASS_SEQUENCE` was changed to `badidea`. There are no other changes or comments on the patch, but this change likely reflected concerns around the overuse of the bypass code; concerns that would be echoed in later years.

[https://codereview.chromium.org/1416273004/patch/1/10001](https://codereview.chromium.org/1416273004/patch/1/10001).

```diff
--- a/components/security_interstitials/core/browser/resources/interstitial_v2.js
+++ b/components/security_interstitials/core/browser/resources/interstitial_v2.js
@@ -40,7 +40,7 @@ function sendCommand(cmd) {
  * @param {string} e The key that was just pressed.
  */
 function handleKeypress(e) {
-  var BYPASS_SEQUENCE = 'danger';
+  var BYPASS_SEQUENCE = 'badidea';
   if (BYPASS_SEQUENCE.charCodeAt(keyPressState) == e.keyCode) {
     keyPressState++;
     if (keyPressState == BYPASS_SEQUENCE.length) {

```

### This is not Safe (2018)

On Januay 03, 2018, [the bypass code was updated again](https://chromium-review.googlesource.com/c/chromium/src/+/843085/4/components/security_interstitials/core/browser/resources/interstitial_large.js), this time to `thisisnotsafe`.

Unlike before, the code was changed explicitly due to growing concern around the growing popularity of being able to bypass SSL warnings in Chrome.

> The security interstitial bypass keyword hasn't changed in two years and
awareness of the bypass has been increased in blogs and social media.
Rotate the keyword to help prevent misuse.
>
> [Jan 03, 2018 03:03UTC - Chromium Issue #843085](https://chromium-review.googlesource.com/c/chromium/src/+/843085)


### dGhpc2lzdW5zYWZl (2018 - Present)

But then, just a few days later, on January 10, 2018, [the bypass code was changed once again](https://chromium-review.googlesource.com/c/chromium/src/+/860418):

`thisisnotesafe` was changed to `dGhpc2lzdW5zYWZl`, in what I can only guess was an attempt at obfuscation.

```bash
$ echo dGhpc2lzdW5zYWZl | base64 -d
thisisunsafe
```

```diff
--- a/components/security_interstitials/core/browser/resources/interstitial_large.js
+++ b/components/security_interstitials/core/browser/resources/interstitial_large.js
@@ -13,7 +13,10 @@
  * @param {string} e The key that was just pressed.
  */
 function handleKeypress(e) {
-  var BYPASS_SEQUENCE = 'thisisnotsafe';
+  // HTTPS errors are serious and should not be ignored. For testing purposes,
+  // other approaches are both safer and have fewer side-effects.
+  // See https://goo.gl/ZcZixP for more details.
+  var BYPASS_SEQUENCE = window.atob('dGhpc2lzdW5zYWZl');
   if (BYPASS_SEQUENCE.charCodeAt(keyPressState) == e.keyCode) {
     keyPressState++;
     if (keyPressState == BYPASS_SEQUENCE.length) {
```

Along with this patch, the Chromium team released a public document titled: [Deprecating Powerful Features on Insecure Origins](https://goo.gl/ZcZixP).

Though it made no mention of the bypass code, it included instructions for how to bypass SSL errors during development and testing. I presume this is what was meant by the "other approaches are both safer and have fewer side-effects" comment in the code snippet above.

> You can use `chrome://flags/#unsafely-treat-insecure-origin-as-secure` to run Chrome, or use the `--unsafely-treat-insecure-origin-as-secure="http://example.com"` flag (replacing `"example.com"` with the origin you actually want to test), which will treat that origin as secure for this session.


## Is this Unsafe?

As of the time of writing, the bypass code (along with the `skippped` typo) has remained unchanged. You can see it in the latest version of [Chromium (140.0.7301.1)](https://chromium.googlesource.com/chromium/src/+/refs/tags/140.0.7301.1/components/security_interstitials/core/browser/resources/interstitial_large.js#51), and it still shows up in blogs and social media posts.

```js
/**
 * This allows errors to be skippped [sic] by typing a secret phrase into the page.
 * @param {string} e The key that was just pressed.
 */
function handleKeypress(e) {
  // HTTPS errors are serious and should not be ignored. For testing purposes,
  // other approaches are both safer and have fewer side-effects.
  // See https://goo.gl/ZcZixP for more details.
  const BYPASS_SEQUENCE = window.atob('dGhpc2lzdW5zYWZl');
  if (BYPASS_SEQUENCE.charCodeAt(keyPressState) === e.keyCode) {
    keyPressState++;
    if (keyPressState === BYPASS_SEQUENCE.length) {
      sendCommand(SecurityInterstitialCommandId.CMD_PROCEED);
      keyPressState = 0;
    }
  } else {
    keyPressState = 0;
  }
}
```


Despite the excavation, I wasn't able to find the exact reason for the bypass code's introduction. It seems to have been a convenience for developers, but it has since become a point of concern due to its potential misuse. The change to base64 encoding was likely an attempt to obscure the code from casual users, but it is by no means a secret.

![thisisunsafe has been rising in popularity since its introduction in 2018](/assets/images/thisisunsafe_trends.png)

SSL-everywhere has been a net-positive for the web, but it's hard to articulate the risks of broken SSL to everyday users. A popular bypass code might not supply enough friction to prevent misuse, and I'm curious to know what benefits it has over using the `--unsafely-treat-insecure-origin-as-secure` flag.

What do you think?
