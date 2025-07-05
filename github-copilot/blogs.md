---
layout: "page"
title: "Blogs"
description: "A collection of blogs to help you get the most out of GitHub Copilot."
excerpt_separator: <!--excerpt_end-->
order: 2
permalink: "/github-copilot/blogs.html"
---

{%- assign date_format = "%Y-%m-%d" -%}

{%- assign posts = site.posts | where: "categories", "Copilot" | sort: 'date' | reverse  -%}
{% include tag-filter.html %}

<ul class="post-list">
  {%- for post in posts -%}
    {% include data-tags-builder.html %}

    <li class="post-item" data-tags="{{ all_tags }}" data-date="{{ post_date_iso }}">
      <a href="{{ post.url | relative_url }}?entry=github-copilot">
        {{ post.date | date: date_format }} - {{ post.title | escape }}
      </a>
      {%- if site.show_excerpts -%}
        {{ post.excerpt }}
      {%- endif -%}
    </li>
  {%- endfor -%}
</ul>
