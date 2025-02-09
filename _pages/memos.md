---
layout: default
title: Memos
permalink: /memos/
---

<div class="memos">
  {% for memo in site.memos reversed %}
    <article class="memo">
      <div class="memo-header" onclick="window.location.href='{{ memo.url }}';" style="cursor: pointer;">
        <div class="memo-metadata">
          <time datetime="{{ memo.date | date_to_xmlschema }}">{{ memo.date | date: "%Y-%m-%d" }}</time>
        </div>
        <h2><a class="memo-link" href="{{ memo.url }}">{{ memo.title }}</a></h2>
        {% if memo.tags %}
          <p class="memo-tags">
            {% for tag in memo.tags %}
              <a href="/tag/{{tag}}">#{{tag}}</a>{% unless forloop.last %} {% endunless %}
            {% endfor %}
          </p>
        {% endif %}
      </div>
      <div class="memo-content">
        {{ memo.content | markdownify }}
      </div>
    </article>
  {% endfor %}
</div>
