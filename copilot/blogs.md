---
layout: "page"
title: "Blogs"
description: "A collection of blogs to help you get the most out of GitHub Copilot."
excerpt_separator: <!--excerpt_end-->
order: 2
---

{%- assign date_format = "%Y-%m-%d" -%}

{%- assign posts = site.posts -%}
{% include tag-filter.html %}

<ul class="post-list">
  {%- for post in posts -%}
    <li class="post-item" data-tags="{{ post.tags | join: ',' | downcase | replace: '_', ' ' | escape }}">
      <a href="{{ post.url | relative_url }}">
        {{ post.date | date: date_format }} - {{ post.title | escape }}
      </a>
      {%- if site.show_excerpts -%}
        {{ post.excerpt }}
      {%- endif -%}
    </li>
  {%- endfor -%}
</ul>