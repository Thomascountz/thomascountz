---
title: Specify Bundler Version
author: Thomas Countz
layout: post
tags: ["ruby"]
---

If you’re like me, you may have both Bundler 1 and Bundler 2 installed on your system. This can make it difficult to use, manage different code bases. Say one requires the older version `1.13.6`, you can do something like

```
gem install bundler -v 1.13.6
```

to install an older version of Bundler, but when you run

```
bundle install
```

You might see something like

```
BUNDLED WITH
   2.1.4
```

in your `Gemfile.lock` file… which is _not_ the same as bundling with `1.13.6`.

You can tell Bundler that you’d like to use a specific version of Bundler by specifying the exact version before the command you which to run, like so

```
bundle _x.x.x_ install
```

To install gems for your project using Bundler `1.13.6`, you can use this command to force Bundler to use the correct version:

```
bundle _1.13.6_ install
```

And you should see

```
BUNDLED WITH
   1.13.6
```

at the end of your `Gemfile.lock` file.

Horray!
