---
title: Third-Party Cookies
author: Thomas Countz
description: What are cookies and how they so dangerous? Let's take a look at the technical side of cookies and what makes them so useful for good and bad actors, alike.
layout: post
tags: ["privacy"]
---

As internet privacy continues to rise in our collective consciousnesses, _cookies_ are caught in the cross-hairs. Cookies aren't always bad, but they can be used to identify you, track your behavior online. Let's take a look at the technical side of cookies and what makes them so useful for good and bad actors, alike.

## Request-Response Cycle

When you visit a website on the internet, your browser sends a _request_ to a _server_. Although there are many stops along the way, a request is eventually routed to a server that houses the files you wish to see in your browser window. This is called the request/response cycle.

![A browser sends an HTTP request to a server. The server then responds with the requested content and it's displayed in the browser.](/assets/images/req-resp-cycle.png)

We call this server the "first-party server," because it is the place where the content that the user has requested is stored—this is the server where the user is expecting to get a webpage from.

## First-Party Cookies

First-party servers sometimes return additional data besides the content that a user has requested, like cookies, for example. They do that by setting the `Set-Cookie` header in response to the request from your browser. After a cookie has been set in a browser, that browser will send back that cookie with every subsequent request to the server.

According to the [Electronic Frontier Foundation](https://www.eff.org/), or EFF, browser cookies "...are a web technology that let websites recognize your browser. Cookies were originally designed to allow sites to offer online shopping carts, save preferences, or keep you logged on to a site."

As an example, after you log into a website, like Facebook, with a username and password, a unique cookie is set in your browser. This unique string is used to identify your browser on every subsequent visit to the site, that way, you don't need to keep on logging in with your username and password.

As another example, if you visit an online shopping site and place things in your cart and then leave, those items may still be there if you later return the site—this can happen without having to login or create an account.

![A first-party server may return a cookie, along with the requested content. This cookie can be used to uniquely identify your browser on subsequent requests to the server.](/assets/images/req-resp-cycle-with-cookie.png)

This is because your browser, after receiving a cookie from a particular server, will **send that same cookie back to the server on every next request**, until that cookie expires or is deleted by the user.

These types of cookies are mostly benign and are not considered "trackers." First-party severs _can_ use cookies to monitor your behavior/save your preferences only when you're interacting with that _particular_ server. That isn't to say that there aren't security implications to using cookies for authentication, but in terms of privacy, the impacts can be mild.

## Third-Party Cookies

Privacy becomes a concern when cookies are used to track you outside of a particular website and across the internet. Cookies often become trackers when your browser, unwittingly, interacts with third-party servers.

![A first-party server may cause your browser to send a request to a third-party server. The third-party server can attach a cookie to the response, just like a first-party server. Every time your browser make a request to this third-party server, the cookie will be included, and this can follow you around the internet.](/assets/images/req-resp-cycle-with-3rd-party-cookie.png)

In this example, your browser makes a request to a first-party server, just like before, but then the first-party server causes your browser to make (sometimes hundreds of) additional requests to servers that may have nothing to do with the content that you're looking for. When this happens, these third-party servers can set cookies just like first-party servers. 

If you remember, your browser only sends back cookies in requests to the servers that originally set them, however if two _different_ first-party servers, say server A and server B, cause your browser to send a request to _the same_ third-party server (like Google Analytics), that third-party server now knows that you've visited both server A and server B. This third-party server is now tracking you across different websites and can build a profile about the kinds of sites that you visit.

Besides cookies, there are additional pieces of identifiable information that your browser sends to a server when making a request. This data, in combination, can build a strong profile about your behavior on the internet, and it's this profile that advertisers use to target ads to you.

## How Website Owners Can Prevent Users From Being Tracked

Often websites don't know that they're aiding advertisers by allowing their site visitors to be tracked, monitored, fingerprinted, and profiled. Adding a social network "share" button, a visitor counter/analytics tool, or even deciding to use certain fonts can cause a website's users to become tracked or their existing profiles added to.

Website developers often use tools & resources built by companies which support major ad networks, like Google, Facebook, and Amazon, but slowly, more an more privacy-conscious alternatives are being developed, like [Font Squirrel](https://www.fontsquirrel.com/) for fonts, and [TinyFeather](/), for analytics. 

TinyFeather provides the kinds of analytics that businesses use to improve their products & services _without_ compromising their users' & customers' privacy. TinyFeather uses anonymous data—this is data that could never be tied back to an individual—to track a website's performance, not a user's behavior.

## Mitigation For Users

There are a lot of browsers & browser tools designed to block third-party cookies. Most modern browsers will provide settings to turn off third-party cookies altogether. Because of the emphasis placed on browser cookies as privacy concern, third-party [advertisers have begun to use other pieces of identifiable information](https://www.nytimes.com/2019/07/03/technology/personaltech/fingerprinting-track-devices-what-to-do.html) in order to build profiles on it's targets.


