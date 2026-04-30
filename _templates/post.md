<%*
const title = await tp.system.prompt('Title');
const slug = title.toLowerCase().trim().replace(/\s+/g, '-').replace(/[^\w-]/g, '');
const date = tp.date.now('YYYY-MM-DD');
const filename = `${date}-${slug}`;
await tp.file.rename(filename);
await tp.file.move(`_drafts/${filename}`);
-%>
---
layout: post
title: "<% title %>"
subtitle: ""
date: <% date %>
description: ""
tags: []
---


