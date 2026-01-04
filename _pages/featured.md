---
layout: page
title: Featured
permalink: /featured
---

{% assign posts = site.posts | where: 'featured', true %}

<section class="posts">
  <h2>*featured</h2>
    <ul>
      {% for post in posts %}
        {% include post_list_item.html post=post %}
      {% endfor %}
    </ul>
</section>