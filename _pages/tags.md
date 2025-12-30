---
layout: default
title: Tags
---

<section class="posts">
  <h1>{{ page.title }}</h1>
  {% assign tags = site.tags | sort %}
  <ul class="tree">
  {% for tag in tags %}
    {% assign tag_name = tag[0] %}
    {% assign tag_posts = tag[1] | sort: "date" | reverse %}
    <li>
      <a class="tag-link" href="/tag/{{ tag_name | slugify }}/">
        {{ tag_name | replace:'-', ' ' }} ({{ tag_posts | size }})
      </a>
      <ul>
        {% for post in tag_posts %}
          <li>
            <a href="{{ post.url | relative_url }}">
              <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y-%m-%d" }}</time>
              {% if post.featured %}
                *
              {% else %}
                &nbsp;
              {% endif %}
              {{ post.title }}
            </a>
          </li>
        {% endfor %}
      </ul>
    </li>
  {% endfor %}
  </ul>
</section>
