---
layout: "page"
title: "News"
description: "Latest updates and articles related to GitHub Copilot."
excerpt_separator: <!--excerpt_end-->
order: 1
---

{%- assign date_format = "%Y-%m-%d" -%}

{%- assign posts = site.news | sort: 'date' | reverse -%}
{% include tag-filter.html %}

<ul class="post-list">
  {%- for post in posts -%}
    {% include data-tags-builder.html %}

    <li class="post-item" data-tags="{{ all_tags }}">
      <a href="{{ post.url | relative_url }}">
        {{ post.date | date: date_format }} - {{ post.title | escape }}
      </a>
      {%- if site.show_excerpts -%}
        {{ post.excerpt }}
      {%- endif -%}
    </li>
  {%- endfor -%}
</ul>
