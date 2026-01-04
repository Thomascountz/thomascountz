---
layout: page
title: Tags
permalink: /tags
---

{%- assign featured_posts = site.posts | where: 'featured', true -%}
{%- assign tags = site.tags | sort -%}

<section class="posts">
  <ul class="tree">
    {%- if featured_posts.size > 0 %}
    <li>
      <a class="tag-link" href="/featured/">*featured ({{ featured_posts | size }})</a>
      <ul>
        {%- for post in featured_posts %}
        {% include post_list_item.html post=post %}
        {%- endfor %}
      </ul>
    </li>
    {%- endif %}
    {%- for tag in tags %}
    {%- assign tag_name = tag[0] -%}
    {%- assign tag_posts = tag[1] | sort: "date" | reverse -%}
    <li>
      <a class="tag-link" href="/tag/{{ tag_name }}/">#{{ tag_name }} ({{ tag_posts | size }})</a>
      <ul>
        {%- for post in tag_posts %}
        {% include post_list_item.html post=post %}
        {%- endfor %}
      </ul>
    </li>
    {%- endfor %}
  </ul>
</section>