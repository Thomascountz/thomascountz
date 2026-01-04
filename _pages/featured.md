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
      <li>
        <a href="{{ site.baseurl }}{{ post.url }}">
            <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%m-%d-%Y" }}</time>
            * {{ post.title }}
        </a>
      </li>
      {% endfor %}
    </ul>
</section>
